//
//  AmazonPublisherServicesAdAdapter.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import Foundation
import HeliumSdk
import DTBiOSSDK
import UIKit

final class AmazonPublisherServicesAdAdapter: NSObject, PartnerAdAdapter {
    /// The current adapter instance
    let adapter: PartnerAdapter

    /// The current PartnerAdLoadRequest containing data relevant to the curent ad request
    let request: PartnerAdLoadRequest

    /// A PartnerAd object with a placeholder (nil) ad object.
    lazy var partnerAd = PartnerAd(ad: nil, details: [:], request: request)

    /// The partner ad delegate to send ad life-cycle events to.
    weak var partnerAdDelegate: PartnerAdDelegate?

    /// Instance of the prebidding controller.
    let prebiddingController: APSPreBiddingController

    /// The completion handler to notify Helium of ad show completion result.
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?

    /// The completion handler to notify Helium of ad load completion result.
    var showCompletion: ((Result<PartnerAd, Error>) -> Void)?

    /// Create a new instance of the adapter.
    /// - Parameters:
    ///   - adapter: The current adapter instance
    ///   - request: The current AdLoadRequest containing data relevant to the curent ad request
    ///   - partnerAdDelegate: The partner ad delegate to notify Helium of ad lifecycle events.
    init(adapter: PartnerAdapter, request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate, prebiddingController: APSPreBiddingController) {
        self.adapter = adapter
        self.request = request
        self.partnerAdDelegate = partnerAdDelegate
        self.prebiddingController = prebiddingController

        super.init()
    }

    /// Attempt to load an ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: The completion handler to notify Helium of ad load completion result.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        loadCompletion = completion

        switch request.format {
        case .banner:
            loadBanner(request: request)

        case .interstitial:
            loadInterstitial(request: request)

        case .rewarded:
            assertionFailure("Rewarded ads are not supported")
        }
    }

    /// Attempt to show the currently loaded ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: The completion handler to notify Helium of ad show completion result.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        switch request.format {
        case .banner:
            // Banner does not have a separate show mechanism
            log(.showSucceeded(partnerAd))
            completion(.success(partnerAd))

        case .interstitial:
            showCompletion = completion
            showInterstitial(viewController: viewController)

        case .rewarded:
            assertionFailure("Rewarded ads are not supported")
        }
    }
}

extension AmazonPublisherServicesAdAdapter {
    // Delegate method for DTBAdInterstitialDispatcherDelegate and DTBAdBannerDispatcherDelegate
    func impressionFired() {
        log(.didTrackImpression(partnerAd))
        partnerAdDelegate?.didTrackImpression(partnerAd) ?? log(.delegateUnavailable)
    }
}
