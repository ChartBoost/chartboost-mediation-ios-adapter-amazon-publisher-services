// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK
import Foundation

/// The Chartboost Mediation Amazon Publisher Services adapter rewarded ad.
final class AmazonPublisherServicesAdapterRewardedAd: AmazonPublisherServicesAdapterAd, PartnerFullscreenAd {
    /// The APS ad dispatcher instance used to load an ad. We have strong reference here to keep it alive while the loading is ongoing.
    private var adLoader: DTBAdInterstitialDispatcher?

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

        loadCompletion = completion

        // APS ads make use of UI-related APIs directly from the thread fetchAd() is called, so we need to do it on the main thread
        DispatchQueue.main.async { [self] in
            // Fetch the creative from the mediation hints.
            let adLoader = DTBAdInterstitialDispatcher(delegate: self)
            adLoader.fetchAd(withParameters: bidPayload)
            self.adLoader = adLoader
        }
    }

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)
        guard !amazonAdapter.isDisabledDueToCOPPA else {
            let error = error(.showFailurePrivacyOptIn, description: "Showing has been disabled due to COPPA restrictions")
            log(.showFailed(error))
            completion(error)
            return
        }

        guard let ad = adLoader else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            showCompletion?(error)
            return
        }

        showCompletion = completion
        ad.show(from: viewController)
    }
}

extension AmazonPublisherServicesAdapterRewardedAd: DTBAdInterstitialDispatcherDelegate {
    func interstitialDidLoad(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.loadSucceeded)
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func interstitial(_ interstitial: DTBAdInterstitialDispatcher?, didFailToLoadAdWith errorCode: DTBAdErrorCode) {
        let error = partnerError(errorCode.rawValue)
        log(.loadFailed(error))
        loadCompletion?(error) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func interstitialWillPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.delegateCallIgnored)
    }

    func interstitialDidPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.showSucceeded)
        showCompletion?(nil) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func interstitialWillDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.delegateCallIgnored)
    }

    func interstitialDidDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, error: nil) ?? log(.delegateUnavailable)
    }

    func interstitialWillLeaveApplication(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.delegateCallIgnored)
    }

    func adClicked() {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }

    func show(fromRootViewController controller: UIViewController) {
        log(.delegateCallIgnored)
    }

    func impressionFired() {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self) ?? log(.delegateUnavailable)
    }

    func videoPlaybackCompleted(_ interstitial: DTBAdInterstitialDispatcher) {
        log(.didReward)
        delegate?.didReward(self) ?? log(.delegateUnavailable)
    }
}
