// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  AmazonPublisherServicesAdapterInterstitialAd.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import Foundation
import HeliumSdk
import DTBiOSSDK

/// The Helium Amazon Publisher Services adapter interstitial ad.
final class AmazonPublisherServicesAdapterInterstitialAd: AmazonPublisherServicesAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { nil }
        
    /// The APS ad dispatcher instance used to load an ad. We have strong reference here to keep it alive while the loading is ongoing.
    private var adLoader: DTBAdInterstitialDispatcher?
    
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
        guard let mediationHints = prebiddingController.bidPayload(heliumPlacementName: request.heliumPlacement) else {
            let error = error(.loadFailureAuctionNoBid)
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }

        loadCompletion = completion
        
        // APS ads make use of UI-related APIs directly from the thread fetchAd() is called, so we need to do it on the main thread
        DispatchQueue.main.async { [self] in
            // Fetch the creative from the mediation hints.
            let adLoader = DTBAdInterstitialDispatcher(delegate: self)
            adLoader.fetchAd(withParameters: mediationHints)
            self.adLoader = adLoader
        }
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        guard !prebiddingController.isDisabledDueToCOPPA else {
            let error = error(.showFailurePrivacyOptIn, description: "Showing has been disabled due to COPPA restrictions")
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }
        
        guard let ad = adLoader else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            showCompletion?(.failure(error))
            return
        }

        showCompletion = completion
        ad.show(from: viewController)
    }
}

extension AmazonPublisherServicesAdapterInterstitialAd: DTBAdInterstitialDispatcherDelegate {
    
    func interstitialDidLoad(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func interstitial(_ interstitial: DTBAdInterstitialDispatcher?, didFailToLoadAdWith errorCode: DTBAdErrorCode) {
        let error = partnerError(errorCode.rawValue)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func interstitialWillPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.delegateCallIgnored)
    }

    func interstitialDidPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func interstitialWillDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.delegateCallIgnored)
    }

    func interstitialDidDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }

    func interstitialWillLeaveApplication(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func show(fromRootViewController controller: UIViewController) {
        log(.delegateCallIgnored)
    }
    
    func impressionFired() {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
