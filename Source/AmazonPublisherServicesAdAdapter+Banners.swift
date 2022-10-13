//
//  AmazonPublisherServicesAdAdapter+Banners.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import Foundation
import HeliumSdk
import DTBiOSSDK

extension AmazonPublisherServicesAdAdapter {
    /// Attempt to load a banner ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - request: The relevant data associated with the current ad load call.
    func loadBanner(request: PartnerAdLoadRequest) {
        guard !prebiddingController.isDisabledDueToCOPPA else {
            loadCompletion?(.failure(error(.loadFailure(request), description: "Loading has been disabled due to COPPA restrictions")))
            return
        }

        // Validate that there is a bid payload available to fetch.
        guard let mediationHints = prebiddingController.bidPayload(heliumPlacementName: request.heliumPlacement) else {
            loadCompletion?(.failure(error(.loadFailure(request), description: "No pre-bid is available to load for placement")))
            return
        }

        // APS banners make use of UI-related APIs directly from the thread fectchBannerAd() is called, so we need to do it on the main thread
        DispatchQueue.main.async { [self] in
            let frame = CGRect(origin: .zero, size: request.size ?? IABStandardAdSize)
            
            // Fetch the creative from the mediation hints.
            let adLoader = DTBAdBannerDispatcher(adFrame: frame, delegate: self)
            adLoader.fetchBannerAd(withParameters: mediationHints)
            self.adLoader = adLoader
        }
    }
}

extension AmazonPublisherServicesAdAdapter: DTBAdBannerDispatcherDelegate {
    func adDidLoad(_ adView: UIView) {
        partnerAd = PartnerAd(ad: adView, details: [:], request: request)
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adFailed(toLoad banner: UIView?, errorCode: Int) {
        loadCompletion?(.failure(error(.loadFailure(request), description: "APS error \(errorCode)"))) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerWillLeaveApplication(_ adView: UIView) {
        // NO-OP
    }
}
