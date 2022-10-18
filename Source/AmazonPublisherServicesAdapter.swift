//
//  AmazonPublisherServicesAdapter.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import Foundation
import HeliumSdk
import DTBiOSSDK
import UIKit

/// The Helium Amazon Publisher Services adapter.
final class AmazonPublisherServicesAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion: String = DTBAds.version()
    
    /// The version of the adapter.
    /// The first digit is Helium SDK's major version. The last digit is the build version of the adapter. The intermediate digits correspond to the partner SDK version.
    let adapterVersion = "4.4.4.2.0"
    
    /// The partner's unique identifier.
    let partnerIdentifier = "amazon_aps"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "Amazon Publisher Services"
    
    /// Convenience accessor for the SDK shared isntance.
    static var amazon: DTBAds { DTBAds.sharedInstance() }

    /// Instance of the prebidding controller.
    private let prebiddingController = APSPreBiddingController()

    /// The last value set on `setGDPRApplies(_:)`.
    private var gdprApplies = false

    /// The last value set on `setGDPRConsentStatus(_:)`.
    private var gdprStatus: GDPRConsentStatus = .unknown
    
    /// The designated initializer for the adapter.
    /// Helium SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Helium SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {}
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        
        guard let appID = configuration.appID, !appID.isEmpty else {
            let error = error(.missingSetUpParameter(key: .appIDKey))
            log(.setUpFailed(error))
            return completion(error)
        }

        // Extract the prebidding settings and initialize the prebidding controller.

        guard let preBidderConfigurations = configuration.preBidderConfigurations, !preBidderConfigurations.isEmpty else {
            let error = error(.missingSetUpParameter(key: .prebidSettingsKey))
            log(.setUpFailed(error))
            return completion(error)
        }

        prebiddingController.setup(settings: preBidderConfigurations)

        // Initialize Amazon APS SDK.
        let amazon = Self.amazon
        amazon.setAppKey(appID)
        amazon.setAdNetworkInfo(.init(networkName: DTBADNETWORK_OTHER))
        amazon.mraidPolicy = CUSTOM_MRAID
        amazon.mraidCustomVersions = ["1.0", "2.0", "3.0"]

        // Wait 0.25 seconds since it takes time for APS to get into an `isReady` state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [unowned self] in
            if amazon.isReady {
                log(.setUpSucceded)
                completion(nil)
            }
            else {
                let error = error(.setUpFailure, description: "Failed to be ready within the expected timeframe of 250ms")
                log(.setUpFailed(error))
                completion(error)
            }
        }

    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        log(.fetchBidderInfoStarted(request))

        guard !prebiddingController.isDisabledDueToCOPPA else {
            let error = error(.fetchBidderInfoFailure(request), description: "Bidder info fetch has been disabled due to COPPA restrictions")
            log(.fetchBidderInfoFailed(request, error: error))
            completion([:])
            return
        }

        prebiddingController.fetchPrebiddingToken(heliumPlacementName: request.heliumPlacement) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let pricePoint):
                if let pricePoint = pricePoint {
                    self.log(.fetchBidderInfoSucceeded(request))
                    return completion([request.heliumPlacement: pricePoint])
                }
                else {
                    let error = self.error(.fetchBidderInfoFailure(request), description: "Price point value not supplied")
                    self.log(.fetchBidderInfoFailed(request, error: error))
                }
            case .failure(let error):
                let error = self.error(.fetchBidderInfoFailure(request), error: error)
                self.log(.fetchBidderInfoFailed(request, error: error))
            }
            completion([:])
        }
    }
    
    /// Indicates if GDPR applies or not.
    /// - parameter applies: `true` if GDPR applies, `false` otherwise.
    func setGDPRApplies(_ applies: Bool) {
        gdprApplies = applies
        updateGDPRConsent()
   }
    
    /// Indicates the user's GDPR consent status.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPRConsentStatus(_ status: GDPRConsentStatus) {
        gdprStatus = status
        updateGDPRConsent()
    }

    private func updateGDPRConsent() {
        guard gdprApplies else {
            return
        }

        // The `setCMPFlavor()` method should be invoked only if GDPR applies to the user.
        // By default, the CMP flavor is the TCFv2 specification which reads the GDPR
        // applicability and consent status directly from `NSUserDefaults` using the following
        // keys:
        // - IABTCF_gdprApplies – 0 if GDPR does not apply for the user or 1 if GDPR does apply for the user
        // - IABTCF_TCString – encoded consent string value
        //
        // Since the Helium SDK does not support the TCFv2 CMP framework, we will be using
        // the MoPub CMP flavor which is a manually specified consent mechanism.
        //
        // The CMP flavor is set again in the event that `setGDPRConsentStatus()` is
        // called before `setGDPRApplies()` by the publisher.
        log(.privacyUpdated(setting: "cmpFlavor", value: DTBCMPFlavor.MOPUB_CMP))
        Self.amazon.setCmpFlavor(.MOPUB_CMP)

        // Translate the explicit consent into the Amazon equivalent.
        let consentStatus: DTBConsentStatus = gdprStatus == .granted ? .EXPLICIT_YES : .EXPLICIT_NO
        log(.privacyUpdated(setting: "consentStatus", value: consentStatus))
        Self.amazon.setConsentStatus(consentStatus)
    }

    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isSubject: `true` if the user is subject, `false` otherwise.
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        log(.privacyUpdated(setting: "isDisabledDueToCOPPA", value: isSubject))

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
        prebiddingController.isDisabledDueToCOPPA = isSubject;
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        let privacyString = privacyString ?? (hasGivenConsent ? "1YN-" : "1YY-")
        log(.privacyUpdated(setting: "ccpaValue", value: privacyString))

        prebiddingController.ccpaValue = privacyString
    }
    
    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Helium SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Helium SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        switch request.format {
        case .interstitial:
            return AmazonPublisherServicesAdapterInterstitialAd(adapter: self, request: request, delegate: delegate, prebiddingController: prebiddingController)
        case .rewarded:
            throw error(.adFormatNotSupported(request))
        case .banner:
            return AmazonPublisherServicesAdapterBannerAd(adapter: self, request: request, delegate: delegate, prebiddingController: prebiddingController)
        }
    }
}

/// Convenience extension to access APS credentials from the configuration.
private extension PartnerConfiguration {
    var appID: String? { credentials[.appIDKey] as? String }

    var preBidderConfigurations: [APSPreBidderConfiguration]? {
        guard let jsonArray = credentials[.prebidSettingsKey] as? [[String: Any]] else {
            return nil
        }
        return APSPreBidderConfiguration.makeConfigurations(from: jsonArray)
    }
}

private extension String {
    /// APS keys
    static let appIDKey = "application_id"
    static let prebidSettingsKey = "prebid_settings"
}
