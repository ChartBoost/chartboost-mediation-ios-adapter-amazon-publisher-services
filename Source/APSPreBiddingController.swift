// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  APSPreBiddingController.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import Foundation
import HeliumSdk

/// Managers all the `APSPreBidder` objects.
class APSPreBiddingController {

    private let queue = DispatchQueue(label: "com.chartboost.Helium.APSPreBiddingController.queue")

    // MARK: - CCPA / COPPA
    
    /// The CCPA value to use for all `APSPreBidder` instances.
    /// - Note: Setting CCPA to `nil` will explicitly set CCPA to does not apply `"1---"`.
    var ccpaValue: String? = nil {
        didSet {
            // The CCPA value has changed. Update all pre-bidders that have already
            // been allocated. This change should be reflected in the next pre-bid
            // attempt.
            let resolvedCCPAValue = ccpaValue ?? "1---"
            queue.sync {
                bidders.forEach { $1.setCCPA(resolvedCCPAValue) }
            }
        }
    }
    
    /// Indicates if the pre-bidding controller is disabled due to COPPA restrictions.
    /// When disabled, all in flight pre-bids will be cancelled and pre-bidding requests will
    /// immediately complete with an error.
    var isDisabledDueToCOPPA: Bool = false
    
    // MARK: - Internal State
    
    /// Current set of bidders. Map of `[Helium Placement Identifier: APSPreBidder]`
    private var bidders: [String: APSPreBidder] = [:]
    
    // MARK: - Setup
    
    /// Sets up all the prebidder instances.
    /// - Parameter settings: Prebidding settings from the Helium SDK.
    func setup(settings: [APSPreBidderConfiguration]) {
        queue.sync {
            // Parse the settings to generate the prebidders.
            // Assumes that there will only ever be a single `CHBHPreBidSettings` per
            // Helium placement identifier.
            bidders = settings.reduce(into: [:]) { partialResult, bidderConfiguration in
                
                // Attempt to create a new bidder for the Helium placement
                guard let bidder = APSPreBidder(configuration: bidderConfiguration) else {
                    return
                }

                // Set the CCPA value before prebidding if it exists.
                if let ccpaValue = ccpaValue {
                    bidder.setCCPA(ccpaValue)
                }

                // Capture the prebidder
                partialResult[bidderConfiguration.heliumPlacement] = bidder
            }
        }
    }
    
    // MARK: - Prebidding
    
    /// Fetches the prebidding token used for RTB auctions.
    /// - Parameter heliumPlacementName: Helium placement name.
    /// - Parameter completion: Closure invoked when the token fetch completes.
    func fetchPrebiddingToken(heliumPlacementName: String, completion: @escaping APSPreBidder.PrebidCallback) {
        // Get the prebidder for the placement.
        guard let prebidder = queue.sync(execute: {
            bidders[heliumPlacementName]
        }) else {
            return completion(.failure(.prebidderInstanceNotFound))
        }

        prebidder.fetchPrebiddingToken(completion: completion)
    }
    
    /// Retrieves the bid payload from a previously fetched token.
    /// - Parameter heliumPlacementName: Helium placement name.
    /// - Returns: Amazon mediation hints (bid payload) associated with the Helium placement name if present; otherwise `nil`.
    func bidPayload(heliumPlacementName: String) -> [AnyHashable: Any]? {
        // Disallow pre-bidding due to COPPA restrictions.
        guard isDisabledDueToCOPPA == false else { return nil }
        
        // Get the prebidder for the placement.
        guard let prebidder = queue.sync(execute: {
            bidders[heliumPlacementName]
        }) else {
            return nil
        }

        // Consume the bidding payload.
        return prebidder.popPrebid()
    }
}
