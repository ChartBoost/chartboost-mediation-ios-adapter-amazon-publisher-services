// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK
import Foundation

/// The Chartboost Mediation Amazon Publisher Services adapter banner ad.
final class AmazonPublisherServicesAdapterBannerAd: AmazonPublisherServicesAdapterAd, PartnerBannerAd {
    /// The partner banner ad view to display.
    var view: UIView?

    /// The loaded partner ad banner size.
    var size: PartnerBannerSize?

    /// The APS ad dispatcher instance used to load an ad. We have strong reference here to keep it alive while the loading is ongoing.
    private var adLoader: DTBAdBannerDispatcher?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)
        guard !amazonAdapter.isDisabledDueToCOPPA else {
            let error = error(.loadFailurePrivacyOptIn, description: "Loading has been disabled due to COPPA restrictions")
            log(.loadFailed(error))
            completion(error)
            return
        }

        // Validate that there is a bid payload available to fetch.
        guard let bidPayload else {
            let error = error(.loadFailureAuctionNoBid)
            log(.loadFailed(error))
            completion(error)
            return
        }

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard let requestedSize = request.bannerSize,
              let loadedSize = BannerSize.largestStandardFixedSizeThatFits(in: requestedSize)?.size else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            completion(error)
            return
        }

        size = PartnerBannerSize(size: loadedSize, type: .fixed)
        loadCompletion = completion

        // APS banners make use of UI-related APIs directly from the thread fectchBannerAd() is called, so we need to do it on the 
        // main thread
        DispatchQueue.main.async { [self] in
            let frame = CGRect(origin: .zero, size: loadedSize)

            // Fetch the creative from the mediation hints.
            let adLoader = DTBAdBannerDispatcher(adFrame: frame, delegate: self)
            adLoader.fetchBannerAd(withParameters: bidPayload)
            self.adLoader = adLoader
        }
    }
}

extension AmazonPublisherServicesAdapterBannerAd: DTBAdBannerDispatcherDelegate {
    func adDidLoad(_ adView: UIView) {
        log(.loadSucceeded)
        view = adView
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adFailed(toLoad banner: UIView?, errorCode: Int) {
        let error = partnerError(errorCode)
        log(.loadFailed(error))
        loadCompletion?(error) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerWillLeaveApplication(_ adView: UIView) {
        log(.delegateCallIgnored)
    }

    func adClicked() {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }

    func impressionFired() {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self) ?? log(.delegateUnavailable)
    }
}
