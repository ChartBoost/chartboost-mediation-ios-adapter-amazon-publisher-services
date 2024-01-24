// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK

/// Manages APS setup and pre-bidding when managed pre-bidding is enabled.
///
/// Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
/// The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
/// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
final class AmazonPublisherServicesAdapterPreBiddingManager: AmazonPublisherServicesAdapterPreBiddingDelegate {

    enum SetUpError: String, Error {
        case invalidCredentialsMissingAppID = "Missing 'application_id'"
        case invalidCredentialsMissingPrebids = "Missing 'prebids'"
        case timeout = "Failed to be ready within the expected timeframe of 250ms"
    }

    enum PreBidError: String, Error {
        case prebidderNotFound = "Adapter prebidder instance not found"
        case loadAlreadyInProgress = "Load already in progress"
    }

    /// The CCPA value to use for all `AmazonPublisherServicesAdapterPreBidder` instances.
    /// - Note: Setting CCPA to `nil` will explicitly set CCPA to does not apply `"1---"`.
    var ccpaPrivacyString: String? = nil {
        didSet {
            // The CCPA value has changed. Update all pre-bidders that have already
            // been allocated. This change should be reflected in the next pre-bid
            // attempt.
            let resolvedCCPAValue = ccpaPrivacyString ?? "1---"
            for bidder in bidders.values {
                bidder.setCCPA(resolvedCCPAValue)
            }
        }
    }

    /// Current set of bidders keyed by Chartboost placement.
    private var bidders: [String: AmazonPublisherServicesAdapterPreBidder] = [:]

    /// Initializes the APS SDK.
    func setUp(with credentials: [String: Any], completion: @escaping (Error?) -> Void) {
        // Extract credentials
        guard let appID = appID(from: credentials), !appID.isEmpty else {
            completion(SetUpError.invalidCredentialsMissingAppID)
            return
        }

        // Extract the prebidding settings and initialize the prebidding controller.
        guard let preBidderConfigurations = preBidderConfigurations(from: credentials), !preBidderConfigurations.isEmpty else {
            completion(SetUpError.invalidCredentialsMissingPrebids)
            return
        }

        // Parse the settings to generate the prebidders.
        // Assumes that there will only ever be a single prebidder per Chartboost placement.
        bidders = preBidderConfigurations.reduce(into: [:]) { partialResult, bidderConfiguration in

            // Attempt to create a new bidder for the Chartboost Mediation placement
            guard let bidder = AmazonPublisherServicesAdapterPreBidder(configuration: bidderConfiguration) else {
                return
            }

            // Set the CCPA value before prebidding if it exists.
            if let ccpaPrivacyString {
                bidder.setCCPA(ccpaPrivacyString)
            }

            // Capture the prebidder
            if let chartboostPlacement = bidderConfiguration.chartboostPlacement {
                partialResult[chartboostPlacement] = bidder
            } else if let heliumPlacement = bidderConfiguration.heliumPlacement {
                partialResult[heliumPlacement] = bidder // backward compatibility
            }
        }

        // Initialize Amazon APS SDK.
        let amazon = DTBAds.sharedInstance()
        amazon.setAppKey(appID)
        amazon.setAdNetworkInfo(.init(networkName: DTBADNETWORK_OTHER))
        amazon.mraidPolicy = CUSTOM_MRAID
        amazon.mraidCustomVersions = ["1.0", "2.0", "3.0"]

        // Wait 0.25 seconds since it takes time for APS to get into an `isReady` state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else {
                return
            }
            if amazon.isReady {
                completion(nil)
            } else {
                completion(SetUpError.timeout)
            }
        }
    }

    /// Handles a prebid operation.
    func onPreBid(request: AmazonPublisherServicesAdapterPreBidRequest, completion: @escaping (AmazonPublisherServicesAdapterPreBidResult) -> Void) {

        // Get the prebidder for the placement.
        guard let prebidder = bidders[request.chartboostPlacement] else {
            completion(.init(error: PreBidError.prebidderNotFound))
            return
        }

        // Have the prebidder load the ad.
        prebidder.fetchPrebiddingToken(completion: completion)
    }

    private func appID(from credentials: [String: Any]) -> String? {
        credentials[.appIDKey] as? String
    }

    private func preBidderConfigurations(from credentials: [String: Any]) -> [AmazonPublisherServicesAdapterPreBidder.Configuration]? {
        guard let prebids = credentials[.prebidsKey] as? [[String: Any]] else {
            return nil
        }
        return prebids.compactMap(AmazonPublisherServicesAdapterPreBidder.Configuration.makeConfiguration(from:))
    }
}
