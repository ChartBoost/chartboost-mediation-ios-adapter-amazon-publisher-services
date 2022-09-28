//
//  AmazonPublisherServicesAdAdapter+Interstitial.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import Foundation
import HeliumSdk
import DTBiOSSDK

extension AmazonPublisherServicesAdAdapter {
    /// Attempt to load an interstitial ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    func loadInterstitial(request: PartnerAdLoadRequest) {
        guard !prebiddingController.isDisabledDueToCOPPA else {
            loadCompletion?(.failure(error(.loadFailure(request), description: "Loading has been disabled due to COPPA restrictions")))
            return
        }

        // Validate that there is a bid payload available to fetch.
        guard let mediationHints = prebiddingController.bidPayload(heliumPlacementName: request.heliumPlacement) else {
            loadCompletion?(.failure(error(.loadFailure(request), description: "No pre-bid is available to load for placement")))
            return
        }

        // Fetch the creative from the mediation hints.
        let adLoader = DTBAdInterstitialDispatcher(delegate: self)
        partnerAd = PartnerAd(ad: adLoader, details: [:], request: request)
        adLoader.fetchAd(withParameters: mediationHints)
    }

    /// Attempt to show the currently loaded interstitial ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    func showInterstitial(viewController: UIViewController) {
        guard !prebiddingController.isDisabledDueToCOPPA else {
            showCompletion?(.failure(error(.showFailure(partnerAd), description: "Showing has been disabled due to COPPA restrictions")))
            return
        }

        guard let ad = partnerAd.ad as? DTBAdInterstitialDispatcher else {
            showCompletion?(.failure(error(.showFailure(partnerAd), description: "Ad instance is nil/not an DTBAdInterstitialDispatcher.")))
            return
        }

        ad.show(from: viewController)
    }
}

extension AmazonPublisherServicesAdAdapter: DTBAdInterstitialDispatcherDelegate {
    func interstitialDidLoad(_ interstitial: DTBAdInterstitialDispatcher?) {
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func interstitial(_ interstitial: DTBAdInterstitialDispatcher?, didFailToLoadAdWith errorCode: DTBAdErrorCode) {
        loadCompletion?(.failure(error(.loadFailure(request), description: "APS error \(errorCode)"))) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func interstitialWillPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        // NO-OP
    }

    func interstitialDidPresentScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        showCompletion?(.success(partnerAd)) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func interstitialWillDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        // NO-OP
    }

    func interstitialDidDismissScreen(_ interstitial: DTBAdInterstitialDispatcher?) {
        log(.didDismiss(partnerAd, error: nil))
        partnerAdDelegate?.didDismiss(partnerAd, error: nil) ?? log(.delegateUnavailable)
    }

    func interstitialWillLeaveApplication(_ interstitial: DTBAdInterstitialDispatcher?) {
        // NO-OP
    }

    func show(fromRootViewController controller: UIViewController) {
        // NO-OP
    }
}
