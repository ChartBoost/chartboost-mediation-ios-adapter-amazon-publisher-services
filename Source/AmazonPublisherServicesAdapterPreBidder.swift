// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK
import Foundation

/// Pre-bidder for a single placement.
/// This class is responsible for pre-bidding and caching of responses and creatives.
class AmazonPublisherServicesAdapterPreBidder {

    // MARK: - State Properties
        
    /// Indicates that a pre-bid load is in progress.
    private(set) var isLoading = false
    
    /// Internal Amazon APS ad loader.
    private let loader: DTBAdLoader
    
    /// Prebid callback.
    private var prebidCallback: ((AmazonPublisherServicesAdapterPreBidResult) -> Void)? = nil

    /// The partner adapter instance.
    private var adapter: PartnerAdapter

    // MARK: - Initialization
    
    /// Initializes the pre-bidder.
    init?(configuration: AmazonPublisherServicesAdapterPreBidder.Configuration, adapter: PartnerAdapter) {
        // Generate the Amazon Ad Size object.
        guard let adSize = Self.amazonAdSize(from: configuration) else {
            return nil
        }
        self.adapter = adapter
        // Generate the ad loader for the slot.
        loader = DTBAdLoader()
        loader.setAdSizes([adSize])
    }
    
    private static func amazonAdSize(from configuration: AmazonPublisherServicesAdapterPreBidder.Configuration) -> DTBAdSize? {
        switch configuration.type {
        case .banner, .adaptiveBanner:
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
        case .rewarded:
            // Currently, all rewarded ads from APS are video
            return DTBAdSize(videoAdSizeWithPlayerWidth: Int(DTB_VIDEO_WIDTH),
                             height: Int(DTB_VIDEO_HEIGHT),
                             andSlotUUID: configuration.partnerPlacement)
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
    func fetchPrebiddingToken(completion: @escaping (AmazonPublisherServicesAdapterPreBidResult) -> Void) {
        // There is already a load in progress.
        guard isLoading == false else {
            completion(.init(error: adapter.error(.prebidFailureUnknown, description: "Load already in progress")))
            return
        }
        
        // Start the prebidding process
        isLoading = true
        
        // Capture the completion callback
        prebidCallback = completion

        // Start prebidding
        loader.loadAd(self)
    }
}

extension AmazonPublisherServicesAdapterPreBidder: DTBAdCallback {
    // MARK: - DTBAdCallback
    
    func onFailure(_ error: DTBAdError) {
        // Clear the cache state
        isLoading = false
        prebidCallback?(.init(error: adapter.partnerError(Int(error.rawValue))))
        prebidCallback = nil
    }
    
    /// The `onSuccess()` callback is called when APS returns a bid.
    func onSuccess(_ adResponse: DTBAdResponse) {
        // Clear the loading state.
        isLoading = false
        prebidCallback?(.init(adResponse: adResponse))
        prebidCallback = nil
    }
}
