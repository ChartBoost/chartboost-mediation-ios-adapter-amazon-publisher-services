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

        let width = request.size?.width ?? 320
        let height = request.size?.height ?? 50
        let frame = CGRect(x: 0, y: 0, width: width, height: height)

        // Fetch the creative from the mediation hints.
        let adLoader = DTBAdBannerDispatcher(adFrame: frame, delegate: self)
        partnerAd = PartnerAd(ad: adLoader, details: [:], request: request)
        adLoader.fetchBannerAd(withParameters: mediationHints)
    }
}

extension AmazonPublisherServicesAdAdapter: DTBAdBannerDispatcherDelegate {
    func adDidLoad(_ adView: UIView) {
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