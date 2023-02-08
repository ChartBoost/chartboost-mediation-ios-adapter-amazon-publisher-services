// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK
import Foundation

/// The Chartboost Mediation Amazon Publisher Services adapter banner ad.
final class AmazonPublisherServicesAdapterBannerAd: AmazonPublisherServicesAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?
    
    /// The APS ad dispatcher instance used to load an ad. We have strong reference here to keep it alive while the loading is ongoing.
    private var adLoader: DTBAdBannerDispatcher?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        guard !prebiddingController.isDisabledDueToCOPPA else {
            let error = error(.loadFailurePrivacyOptIn, description: "Loading has been disabled due to COPPA restrictions")
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }
        
        // Validate that there is a bid payload available to fetch.
        guard let mediationHints = prebiddingController.bidPayload(chartboostMediationPlacementName: request.chartboostPlacement) else {
            let error = error(.loadFailureAuctionNoBid)
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }
        
        loadCompletion = completion

        // APS banners make use of UI-related APIs directly from the thread fectchBannerAd() is called, so we need to do it on the main thread
        DispatchQueue.main.async { [self] in
            let frame = CGRect(origin: .zero, size: request.size ?? IABStandardAdSize)
            
            // Fetch the creative from the mediation hints.
            let adLoader = DTBAdBannerDispatcher(adFrame: frame, delegate: self)
            adLoader.fetchBannerAd(withParameters: mediationHints)
            self.adLoader = adLoader
        }
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }
}

extension AmazonPublisherServicesAdapterBannerAd: DTBAdBannerDispatcherDelegate {
    
    func adDidLoad(_ adView: UIView) {
        log(.loadSucceeded)
        inlineView = adView
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adFailed(toLoad banner: UIView?, errorCode: Int) {
        let error = partnerError(errorCode)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerWillLeaveApplication(_ adView: UIView) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func impressionFired() {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
