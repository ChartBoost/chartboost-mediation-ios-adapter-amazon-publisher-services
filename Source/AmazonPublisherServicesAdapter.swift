//
//  AmazonPublisherServicesAdapter.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import Foundation
import HeliumSdk
import DTBiOSSDK
import UIKit

final class AmazonPublisherServicesAdapter: ModularPartnerAdapter {
    /// Get the version of the partner SDK.
    let partnerSDKVersion: String = DTBAds.version()
    
    /// Get the version of the mediation adapter.
    let adapterVersion = "4.4.4.2.0"
    
    /// Get the internal name of the partner.
    let partnerIdentifier = "amazon_aps"
    
    /// Get the external/official name of the partner.
    let partnerDisplayName = "Amazon Publisher Services"
    
    /// Storage of adapter instances.  Keyed by the request identifier.
    var adAdapters: [String: PartnerAdAdapter] = [:]

    /// Convenience accessor for the SDK shared isntance.
    static var amazon: DTBAds { DTBAds.sharedInstance() }

    /// Instance of the prebidding controller.
    private let prebiddingController = APSPreBiddingController()

    /// The last value set on `setGDPRApplies(_:)`.
    private var gdprApplies = false

    /// The last value set on `setGDPRConsentStatus(_:)`.
    private var gdprStatus: GDPRConsentStatus = .unknown

    /// Provides a new ad adapter in charge of communicating with a single partner ad instance.
    func makeAdAdapter(request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate) throws -> PartnerAdAdapter {
        guard request.format != .rewarded else {
            throw error(.loadFailure(request), description: "Rewarded ads are not supported.")
        }

        let adapter = AmazonPublisherServicesAdAdapter(adapter: self, request: request, partnerAdDelegate: partnerAdDelegate, prebiddingController: prebiddingController)
        return adapter
    }

    /// Onitialize the partner SDK so that it's ready to request and display ads.
    /// - Parameters:
    ///   - configuration: The necessary initialization data provided by Helium.
    ///   - completion: Handler to notify Helium of task completion.
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
    
    /// Compute and return a bid token for the bid request.
    /// - Parameters:
    ///   - request: The necessary data associated with the current bid request.
    ///   - completion: Handler to notify Helium of task completion.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]) -> Void) {
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
    
    /// Notify the partner SDK of GDPR applicability as determined by the Helium SDK.
    /// - Parameter applies: true if GDPR applies, false otherwise.
    func setGDPRApplies(_ applies: Bool) {
        gdprApplies = applies
        updateGDPRConsent()
   }
    
    /// Notify the partner SDK of the GDPR consent status as determined by the Helium SDK.
    /// - Parameter status: The user's current GDPR consent status.
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
        Self.amazon.setCmpFlavor(.MOPUB_CMP)

        // Translate the explicit consent into the Amazon equivalent.
        let consentStatus: DTBConsentStatus = gdprStatus == .granted ? .EXPLICIT_YES : .EXPLICIT_NO
        Self.amazon.setConsentStatus(consentStatus)
    }

    /// Notify the partner SDK of the COPPA subjectivity as determined by the Helium SDK.
    /// - Parameter isSubject: True if the user is subject to COPPA, false otherwise.
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
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
    
    /// Notify the partner SDK of the CCPA privacy String as supplied by the Helium SDK.
    /// - Parameters:
    ///   - hasGivenConsent: True if the user has given CCPA consent, false otherwise.
    ///   - privacyString: The CCPA privacy String.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        let privacyString = privacyString ?? (hasGivenConsent ? "1YN-" : "1YY-")
        prebiddingController.ccpaValue = privacyString
    }
}

/// Convenience extension to access APS credentials from the configuration.
private extension PartnerConfiguration {
    var appID: String? { credentials[.appIDKey] as? String }

    var preBidderConfigurations: [APSPreBidderConfiguration]? {
        guard let jsonArray = credentials[.prebidSettingsKey] as? [[String: Any]] else {
            return nil
        }
        let decoder = JSONDecoder()
        var prebidderConfigurations = [APSPreBidderConfiguration]()
        jsonArray.forEach { json in
            guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
                return
            }
            guard let preBidSettings = try? decoder.decode(APSPreBidSettings.self, from: data) else {
                return
            }
            let settings = json["settings"] as? [String: Any]
            let configuration = preBidSettings.asAPSPreBidderConfiguration(settings: settings)
            prebidderConfigurations.append(configuration)
        }
        return prebidderConfigurations
    }
}

private extension String {
    /// APS keys
    static let appIDKey = "application_id"
    static let prebidSettingsKey = "prebid_settings"
}
