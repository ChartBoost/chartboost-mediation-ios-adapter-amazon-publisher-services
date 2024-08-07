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
final class AmazonPublisherServicesAdapterPreBiddingManager: NSObject, AmazonPublisherServicesAdapterPreBiddingDelegate {
    enum SetUpError: String, Error {
        case timeout = "Failed to be ready within the expected timeframe of 250ms"
    }

    enum PreBidError: String, Error {
        case invalidPrebidSettings = "Invalid pre-bid settings found for this placement"
        case loadAlreadyInProgress = "Pre-bid already in progress for this placement"
    }

    /// The CCPA value to use when loading a APS ad.
    var ccpaPrivacyString: String?

    /// Current set of pre-bidders keyed by Chartboost placement.
    private var preBidders: [String: PreBidder] = [:]

    /// Initializes the APS SDK.
    /// - note: The use of @objc and an optional completion is required by some internal Chartboost tests.
    @objc func setUp(withAppID appID: String, completion: ((Error?) -> Void)?) {
        // Initialize Amazon APS SDK.
        let amazon = DTBAds.sharedInstance()
        amazon.setAppKey(appID)
        amazon.setAdNetworkInfo(.init(networkName: DTBADNETWORK_OTHER))
        amazon.mraidPolicy = CUSTOM_MRAID
        amazon.mraidCustomVersions = ["1.0", "2.0", "3.0"]

        // Wait 0.25 seconds since it takes time for APS to get into an `isReady` state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if amazon.isReady {
                completion?(nil)
            } else {
                completion?(SetUpError.timeout)
            }
        }
    }

    /// Handles a prebid operation.
    func onPreBid(
        request: AmazonPublisherServicesAdapterPreBidRequest,
        completion: @escaping (AmazonPublisherServicesAdapterPreBidResult) -> Void
    ) {
        // This method is called on a background thread, but `DTBAdLoader` calls its callback on the
        // main thread. In order to have thread safe access to `preBidders`, we will synchronize
        // access on the main thread.
        DispatchQueue.main.async {
            // Fail if a pre-bid is already ongoing for this placement.
            guard self.preBidders[request.mediationPlacement] == nil else {
                completion(.init(error: PreBidError.loadAlreadyInProgress))
                return
            }

            // Create the Amazon ad size object needed for the loader
            // Generate the Amazon Ad Size object.
            guard let adSize = self.makeAmazonAdSize(request: request) else {
                completion(.init(error: PreBidError.invalidPrebidSettings))
                return
            }

            // Create pre-bidder and start loading
            let preBidder = PreBidder(adSize: adSize, ccpaPrivacyString: self.ccpaPrivacyString, keywords: request.keywords)
            self.preBidders[request.mediationPlacement] = preBidder   // hold on to the pre-bidder until it is done loading
            preBidder.load { [weak self] result in
                // Just in case the callback is not made on the main thread in the future.
                DispatchQueue.main.async {
                    self?.preBidders[request.mediationPlacement] = nil  // discard it so another load can happen
                    completion(result)
                }
            }
        }
    }

    private func makeAmazonAdSize(request: AmazonPublisherServicesAdapterPreBidRequest) -> DTBAdSize? {
        let settings = request.amazonSettings
        switch request.format {
        case PartnerAdFormats.banner:
            // Fixed banner format requires non-0 height
            guard request.bannerSize?.type != .fixed || settings.height > 0 else {
                return nil
            }
            // Banner format requires a non-0 width
            guard settings.width > 0 else {
                return nil
            }
            // Adaptive banners allow height to 0, meaning a flexible height.
            if settings.video {
                return DTBAdSize(
                    videoAdSizeWithPlayerWidth: settings.width,
                    height: settings.height,
                    andSlotUUID: settings.partnerPlacement
                )
            } else {
                return DTBAdSize(
                    bannerAdSizeWithWidth: settings.width,
                    height: settings.height,
                    andSlotUUID: settings.partnerPlacement
                )
            }
        case PartnerAdFormats.interstitial:
            if settings.video {
                return DTBAdSize(videoAdSizeWithSlotUUID: settings.partnerPlacement)
            } else {
                return DTBAdSize(interstitialAdSizeWithSlotUUID: settings.partnerPlacement)
            }
        case PartnerAdFormats.rewarded:
            // Currently, all rewarded ads from APS are video
            return DTBAdSize(
                videoAdSizeWithPlayerWidth: Int(DTB_VIDEO_WIDTH),
                height: Int(DTB_VIDEO_HEIGHT),
                andSlotUUID: settings.partnerPlacement
            )
        default:
            // Ad format unsupported.
            return nil
        }
    }

    /// Performs one pre-bid operation by loading a APS ad.
    private class PreBidder: DTBAdCallback {
        private class WeakCallback: DTBAdCallback {
            weak var weakCallback: DTBAdCallback?

            init(_ weakCallback: DTBAdCallback) {
                self.weakCallback = weakCallback
            }

            // MARK: - DTBAdCallback

            func onFailure(_ error: DTBAdError) {
                weakCallback?.onFailure?(error)
            }

            func onSuccess(_ adResponse: DTBAdResponse) {
                weakCallback?.onSuccess(adResponse)
            }
        }

        /// Internal Amazon APS ad loader.
        private let loader: DTBAdLoader

        /// Prebid load completion.
        private var completion: ((AmazonPublisherServicesAdapterPreBidResult) -> Void)?

        /// Initializes the pre-bidder.
        init(adSize: DTBAdSize, ccpaPrivacyString: String?, keywords: [String: String]) {
            loader = DTBAdLoader()
            loader.setAdSizes([adSize])
            if let ccpaPrivacyString {
                loader.putCustomTarget(ccpaPrivacyString, withKey: "us_privacy")
            }
            for (key, value) in keywords {
                loader.putCustomTarget(value, withKey: key)
            }
        }

        func load(completion: @escaping (AmazonPublisherServicesAdapterPreBidResult) -> Void) {
            self.completion = completion
            // `DTBAdLoader` keeps a strong reference to the callback, and since we keep a strong 
            // reference to the loader, this creates a retain loop. To fix this, we will wrap the
            // callback with a weak reference to break the retain cycle.
            let callback = WeakCallback(self)
            loader.loadAd(callback)
        }

        // MARK: - DTBAdCallback

        func onFailure(_ error: DTBAdError) {
            completion?(.init(error: NSError(domain: "com.chartboost.mediation.partner", code: Int(error.rawValue))))
            completion = nil
        }

        /// The `onSuccess()` callback is called when APS returns a bid.
        func onSuccess(_ adResponse: DTBAdResponse) {
            completion?(.init(adResponse: adResponse))
            completion = nil
        }
    }
}
