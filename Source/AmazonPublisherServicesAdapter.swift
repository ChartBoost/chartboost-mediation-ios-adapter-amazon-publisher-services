// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK
import Foundation
import UIKit

/// The Chartboost Mediation Amazon Publisher Services adapter.
final class AmazonPublisherServicesAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    var partnerSDKVersion: String { APS.version() }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.4.9.0.1"
    
    /// The partner's unique identifier.
    let partnerID = "amazon_aps"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "Amazon Publisher Services"

    /// A delegate that performs pre-bidding operations by integrating directly with the Amazon Publisher Services SDK.
    ///
    /// Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
    /// The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
    /// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
    static weak var preBiddingDelegate: AmazonPublisherServicesAdapterPreBiddingDelegate?

    /// Info required by Amazon Publisher Services SDK to load ads during pre-bidding, configured on the
    /// Chartboost Mediation dashboard, and obtained on setup. Keyed by Mediation placement.
    private var preBidSettings: [String: AmazonPublisherServicesAdapterPreBidRequest.AmazonSettings] = [:]

    /// Manages APS setup and pre-bidding when managed pre-bidding is enabled.
    ///
    /// Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
    /// The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
    /// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
    private lazy var preBiddingManager = AmazonPublisherServicesAdapterPreBiddingManager()

    /// Bid payloads keyed by Chartboost placement.
    /// Holds the payloads obtained from pre-bidding operations, which are needed to load an ad.
    private var bidPayloads: [String: [AnyHashable: Any]] = [:]

    /// Indicates if ad loading and showing is disabled due to COPPA restrictions.
    /// When disabled, all in flight pre-bids will be cancelled and pre-bidding requests will
    /// immediately complete with an error.
    private(set) var isDisabledDueToCOPPA = false

    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {}
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.setUpStarted)

        // Extract the pre-bid settings needed later on on pre-bid operations.
        preBidSettings = configuration.preBidSettings
        guard !preBidSettings.isEmpty else {
            let error = error(.initializationFailureInvalidCredentials, description: "Missing '\(String.prebidsKey)'")
            log(.setUpFailed(error))
            completion(.failure(error))
            return
        }

        // Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
        // The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
        // For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
        if configuration.useManagedPreBidding && Self.preBiddingDelegate == nil {
            // Use internal pre-bidding manager to initialize APS
            log("Using managed prebidding and setup")

            // Extract credentials
            guard let appID = configuration.appID, !appID.isEmpty else {
                let error = error(.initializationFailureInvalidCredentials, description: "Missing '\(String.appIDKey)'")
                log(.setUpFailed(error))
                completion(.failure(error))
                return
            }

            // Initialize APS
            Self.preBiddingDelegate = preBiddingManager
            preBiddingManager.setUp(withAppID: appID) { [weak self] error in
                if let error = error {
                    self?.log(.setUpFailed(error))
                    completion(.failure(error))
                } else {
                    self?.log(.setUpSucceded)
                    completion(.success([:]))
                }
            }
        } else {
            // Succeed immediately. The publisher is expected to manage APS initialization directly.
            log("Relying on publisher-side APS setup and prebidding integration")
            log(.setUpSucceded)
            completion(.success([:]))
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {
        log(.fetchBidderInfoStarted(request))

        // Disable bidding for underage users
        guard !isDisabledDueToCOPPA else {
            let error = error(.prebidFailureUnknown, description: "Bidder info fetch has been disabled due to COPPA restrictions")
            log(.fetchBidderInfoFailed(request, error: error))
            completion(.failure(error))
            return
        }

        // Fail if no pre-bidding delegate was set by the publisher (does not apply when managed pre-bidding is enabled)
        guard let preBiddingDelegate = Self.preBiddingDelegate else {
            let error = error(.prebidFailurePartnerNotIntegrated, description: "Prebidding delegate not set by publisher.")
            log(.fetchBidderInfoFailed(request, error: error))
            completion(.failure(error))
            return
        }

        // Fail if the corresponding pre-bid info was not found in the credentials dictionary obtained on setup.
        guard let amazonSettings = preBidSettings[request.mediationPlacement] else {
            let error = error(.prebidFailureUnknown, description: "Failed to find pre-bid settings for this placement")
            log(.fetchBidderInfoFailed(request, error: error))
            completion(.failure(error))
            return
        }

        // Start pre-bidding operation.

        // Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
        // The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
        // For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
        let adapterRequest = AmazonPublisherServicesAdapterPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.format,
            bannerSize: request.bannerSize,
            amazonSettings: amazonSettings
        )
        preBiddingDelegate.onPreBid(request: adapterRequest) { [weak self] result in
            guard let self else {
                return
            }
            if let adInfo = result.adInfo {
                // Success: save the bid payload to use later on load, return the price point.
                self.log(.fetchBidderInfoSucceeded(request))
                self.bidPayloads[request.mediationPlacement] = adInfo.bidPayload
                completion(.success([request.mediationPlacement: adInfo.pricePoint]))
            } else {
                // Failure
                let error = result.error ?? self.error(.prebidFailureUnknown)
                self.log(.fetchBidderInfoFailed(request, error: error))
                completion(.failure(error))
            }
        }
    }

    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        // This partner supports TCFv2 strings for GDPR
        if let privacyString = consents[ConsentKeys.usp] {
            preBiddingManager.ccpaPrivacyString = privacyString
            log(.privacyUpdated(setting: "ccpaValue", value: privacyString))
        }
    }

    /// Indicates that the user is underage signal has changed.
    /// - parameter isUserUnderage: `true` if the user is underage as determined by the publisher, `false` otherwise.
    func setIsUserUnderage(_ isUserUnderage: Bool) {
        // Per Amazon APS documentation:
        // The Children’s Online Privacy Protection Act (COPPA) is a United States federal law that is designed to give parents control over the
        // information collected from their young children online. COPPA prohibits the collection, use, or disclosure of personal information from
        // children under 13 unless you have provided notice and received their parent’s consent. Parental consent must be verifiable (e.g., having the
        // parent fill out a consent form, or checking the parent’s government-issued ID).
        //
        // Apps that are directed at children under 13 are not eligible to participate in TAM nor work with APS. This is because of restrictions on
        // advertising found in COPPA and in related regulations relating to online advertising. You are responsible for complying with the restrictions
        // to allow advertisement to be served on a child directed app and, when applicable to your app, with COPPA. COPPA is enforced by the FTC and
        // the penalties for violating COPPA can be as high as $16,000 per violation.
        //
        // Even if your app is directed at a mixed audience, including people both over and under the age of 13, you may not show ads from APS to
        // users you know are under 13. This applies equally even in an app that is not child-directed. For example, if you ask a user for their age and
        // they indicate they are under 13, you may not show an ad to them that you source from the APS integration and/or TAM.
        self.isDisabledDueToCOPPA = isUserUnderage
        log(.privacyUpdated(setting: "isDisabledDueToCOPPA", value: isUserUnderage))
    }
    
    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        // First pop the bid payload for the requested placement, previously obtained during pre-bidding.
        let bidPayload = bidPayloads[request.mediationPlacement]
        bidPayloads[request.mediationPlacement] = nil

        // This partner supports multiple loads for the same partner placement.
        return AmazonPublisherServicesAdapterBannerAd(adapter: self, request: request, delegate: delegate, bidPayload: bidPayload)
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        // First pop the bid payload for the requested placement, previously obtained during pre-bidding.
        let bidPayload = bidPayloads[request.mediationPlacement]
        bidPayloads[request.mediationPlacement] = nil

        // This partner supports multiple loads for the same partner placement.
        switch request.format {
        case PartnerAdFormats.interstitial:
            return AmazonPublisherServicesAdapterInterstitialAd(adapter: self, request: request, delegate: delegate, bidPayload: bidPayload)
        case PartnerAdFormats.rewarded:
            return AmazonPublisherServicesAdapterRewardedAd(adapter: self, request: request, delegate: delegate, bidPayload: bidPayload)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }

    /// Maps a partner prebid error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a fetch bidder info completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapPrebidError(_ error: Error) -> ChartboostMediationError.Code? {
        guard let errorCode = UInt32(exactly: (error as NSError).code) else {
            return nil
        }

        let dtbErrorCode = DTBAdError(errorCode)

        switch dtbErrorCode {
        case NETWORK_ERROR:
            return .prebidFailureNetworkingError
        case NETWORK_TIMEOUT:
            return .prebidFailureTimeout
        case NO_FILL:
            return .prebidFailureUnknown
        case INTERNAL_ERROR:
            return .prebidFailureUnknown
        case REQUEST_ERROR:
            return .prebidFailureInvalidArgument
        default:
            return nil
        }
    }
    
    /// Maps a partner load error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a load completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapLoadError(_ error: Error) -> ChartboostMediationError.Code? {
        guard let code = DTBAdErrorCode(rawValue: (error as NSError).code) else {
            return nil
        }
        switch code {
        case .SampleErrorCodeBadRequest:
            return .loadFailureInvalidAdRequest
        case .SampleErrorCodeUnknown:
            return .loadFailureUnknown
        case .SampleErrorCodeNetworkError:
            return .loadFailureNetworkingError
        case .SampleErrorCodeNoInventory:
            return .loadFailureNoFill
        default:
            return nil
        }
    }
}

private extension String {
    /// APS configuration keys
    static let appIDKey = "application_id"
    static let prebidsKey = "prebids"
    static let managedPrebiddingKey = "managed_prebidding"
}

/// Convenience extension to access APS credentials from the configuration.
private extension PartnerConfiguration {

    var appID: String? {
        credentials[.appIDKey] as? String
    }

    var preBidSettings: [String: AmazonPublisherServicesAdapterPreBidRequest.AmazonSettings] {
        guard let prebids = credentials[.prebidsKey] as? [[String: Any]] else {
            return [:]
        }
        return Dictionary(grouping: prebids) { prebid in
            prebid["chartboost_placement"] as? String ?? prebid["helium_placement"] as? String ?? ""
        }
        .compactMapValues(\.first)
        .compactMapValues(AmazonPublisherServicesAdapterPreBidRequest.AmazonSettings.init(dictionary:))
    }

    var useManagedPreBidding: Bool {
        credentials[.managedPrebiddingKey] as? Bool ?? false
    }
}
