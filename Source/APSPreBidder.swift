// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  APSPreBidder.swift
//  ChartboostMediationAdapterAmazonPublisherServices
//

import ChartboostMediationSDK
import DTBiOSSDK
import Foundation

/// Pre-bidder for a single placement.
/// This class is responsible for pre-bidding and caching of responses and creatives.
class APSPreBidder {
    typealias PrebidCallback = (Result<String?, Error>) -> Void

    // MARK: - State Properties
        
    /// Indicates that a pre-bid load is in progress.
    private(set) var isLoading: Bool = false
    
    /// Internal Amazon APS ad loader.
    private let loader: DTBAdLoader
    
    /// Prebid callback.
    private var prebidCallback: PrebidCallback? = nil
    
    /// The partner adapter instance.
    private var adapter: PartnerAdapter
    
    // MARK: - Caches
    
    /// Current pre-bid used to inform the Chartboost Mediation ad server where APS should be slotted into the auction.
    private(set) var amazonPricePoint: String? = nil
    
    /// Current cached Amazon APS mediation hints that are associated with `amazonPricePoint`.
    private var amazonMediationHints: [AnyHashable: Any]? = nil
    
    // MARK: - Initialization
    
    /// Initializes the pre-bidder.
    init?(configuration: APSPreBidderConfiguration, adapter: PartnerAdapter) {
        // Generate the Amazon Ad Size object.
        guard let adSize = Self.amazonAdSize(from: configuration) else {
            return nil
        }
        self.adapter = adapter
        // Generate the ad loader for the slot.
        loader = DTBAdLoader()
        loader.setAdSizes([adSize])
    }
    
    private static func amazonAdSize(from configuration: APSPreBidderConfiguration) -> DTBAdSize? {
        switch configuration.type {
        case .banner:
            // Banner format requires width and height
            guard let width = configuration.width, let height = configuration.height else {
                return nil
            }
            if configuration.video == true {
                return DTBAdSize(videoAdSizeWithPlayerWidth: width, height: height, andSlotUUID: configuration.partnerPlacement)
            } else {
                return DTBAdSize(bannerAdSizeWithWidth: width, height: height, andSlotUUID: configuration.partnerPlacement)
            }
        case .interstitial:
            if configuration.video == true {
                return DTBAdSize(videoAdSizeWithSlotUUID: configuration.partnerPlacement)
            } else {
                return DTBAdSize(interstitialAdSizeWithSlotUUID: configuration.partnerPlacement)
            }
        }
    }
    
    // MARK: - CCPA
    
    /// Sets the CCPA value for the pre-bidder.
    /// - Parameter value: The IAB US privacy CCPA string.
    func setCCPA(_ value: String) {
        loader.putCustomTarget(value, withKey: "us_privacy")
    }
    
    // MARK: - Pre-Bidding
    
    /// Perform a pre-bid if one is not already running.
    /// - Parameter completion: Completion block containing the fetched token.
    func fetchPrebiddingToken(completion: @escaping PrebidCallback) {
        // There is already a load in progress.
        guard isLoading == false else {
            return completion(.failure(adapter.error(.prebidFailureLoadInProgress)))
        }
        
        // Start the prebidding process
        isLoading = true
        
        // Capture the completion callback
        prebidCallback = completion
        
        // Clear out the cached state
        amazonPricePoint = nil
        amazonMediationHints = nil
        
        // Start prebidding
        loader.loadAd(self)
    }
    
    /// Consumes the pre-bid price point and associated mediation hints.
    /// - Returns: The pre-bid's mediation hints if available; otherwise `nil`.
    func popPrebid() -> [AnyHashable: Any]? {
        // If currently loading, do nothing since it's not ready yet.
        guard isLoading == false else {
            return nil
        }
        
        // Capture the current mediation hints
        let hints = amazonMediationHints
        
        // Clear out the existing price point and hints
        amazonPricePoint = nil
        amazonMediationHints = nil
        
        return hints
    }
}

extension APSPreBidder: DTBAdCallback {
    // MARK: - DTBAdCallback
    
    func onFailure(_ error: DTBAdError) {
        // Clear the cache state
        amazonPricePoint = nil
        amazonMediationHints = nil
        isLoading = false
        prebidCallback?(.failure(adapter.partnerError(Int(error.rawValue))))
        prebidCallback = nil
    }
    
    /// The `onSuccess()` callback is called when APS returns a bid.
    func onSuccess(_ adResponse: DTBAdResponse) {
        // Capture the encoded Amazon price point.
        amazonPricePoint = adResponse.amznSlots()
        
        // Returns our ad tag that we use to render the creative.
        // Store this client side and pass it to us when we are rendering.
        amazonMediationHints = adResponse.mediationHints()
        
        // Clear the loading state.
        isLoading = false

        prebidCallback?(.success(amazonPricePoint))
        prebidCallback = nil
    }
}
