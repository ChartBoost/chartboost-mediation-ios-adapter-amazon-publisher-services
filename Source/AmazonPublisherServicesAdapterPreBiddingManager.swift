
import ChartboostMediationSDK
import DTBiOSSDK

final class AmazonPublisherServicesAdapterPreBiddingManager: AmazonPublisherServicesAdapterPreBiddingDelegate {

    unowned private let adapter: AmazonPublisherServicesAdapter

    // TODO: Comments
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

    /// Current set of bidders. Map of `[Chartboost Mediation Placement Identifier: AmazonPublisherServicesAdapterPreBidder]`
    private var bidders: [String: AmazonPublisherServicesAdapterPreBidder] = [:]

    init(adapter: AmazonPublisherServicesAdapter) {
        self.adapter = adapter
    }

    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        // Extract credentials
        guard let appID = configuration.appID, !appID.isEmpty else {
            let error = adapter.error(.initializationFailureInvalidCredentials, description: "Missing \(String.appIDKey)")
            adapter.log(.setUpFailed(error))
            completion(error)
            return
        }

        // Extract the prebidding settings and initialize the prebidding controller.
        guard let preBidderConfigurations = configuration.preBidderConfigurations, !preBidderConfigurations.isEmpty else {
            let error = adapter.error(.initializationFailureInvalidCredentials, description: "Missing \(String.prebidsKey)")
            adapter.log(.setUpFailed(error))
            completion(error)
            return
        }

        // Parse the settings to generate the prebidders.
        // Assumes that there will only ever be a single `CHBHPreBidSettings` per
        // Chartboost Mediation placement identifier.
        bidders = preBidderConfigurations.reduce(into: [:]) { partialResult, bidderConfiguration in

            // Attempt to create a new bidder for the Chartboost Mediation placement
            guard let bidder = AmazonPublisherServicesAdapterPreBidder(configuration: bidderConfiguration, adapter: adapter) else {
                return
            }

            // TODO: Do not generate all loaders on setup?
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
                adapter.log(.setUpSucceded)
                completion(nil)
            } else {
                let error = adapter.error(.initializationFailureTimeout, description: "Failed to be ready within the expected timeframe of 250ms")
                adapter.log(.setUpFailed(error))
                completion(error)
            }
        }
    }

    func onPreBid(request: AmazonPublisherServicesAdapterPreBidRequest, completion: @escaping (AmazonPublisherServicesAdapterPreBidResult) -> Void) {

        // Get the prebidder for the placement.
        guard let prebidder = bidders[request.chartboostPlacement] else {
            let error = adapter.error(.prebidFailureAdapterNotFound, description: "Adapter prebidder instance not found")
            completion(.init(error: error))
            return
        }

        prebidder.fetchPrebiddingToken(completion: completion)
    }
}

/// Convenience extension to access APS credentials from the configuration.
private extension PartnerConfiguration {

    var appID: String? { credentials[.appIDKey] as? String }

    var preBidderConfigurations: [AmazonPublisherServicesAdapterPreBidder.Configuration]? {
        guard let prebids = credentials[.prebidsKey] as? [[String: Any]] else {
            return nil
        }
        return prebids.compactMap(AmazonPublisherServicesAdapterPreBidder.Configuration.makeConfiguration(from:))
    }
}