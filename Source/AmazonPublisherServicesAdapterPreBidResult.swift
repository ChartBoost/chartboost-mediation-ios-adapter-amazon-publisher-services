// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import DTBiOSSDK
import Foundation

/// A result model containing the ad info obtained by publishers at the end of an APS load during pre-bidding.
///
/// Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
/// The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
/// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
@objcMembers
public final class AmazonPublisherServicesAdapterPreBidResult: NSObject {
    /// APS Ad info obtained during pre-bidding.
    @objc(AmazonPublisherServicesAdapterPreBidAdInfo)
    @objcMembers
    public final class AdInfo: NSObject {
        /// The associated price point.
        /// Corresponds to `DTBAdResponse.amznSlots()`.
        public let pricePoint: String

        /// The associated bid payload.
        /// Corresponds to `DTBAdResponse.mediationHints()`.
        public let bidPayload: [AnyHashable: Any]

        /// Public constructor to create an ad info model.
        /// Generally ``AmazonPublisherServicesAdapterPreBidResult\init(adResponse:)`` should be used instead.
        public init(pricePoint: String, bidPayload: [AnyHashable: Any]) {
            self.pricePoint = pricePoint
            self.bidPayload = bidPayload
        }
    }

    /// The error that provides context on why the pre-bidding operation failed.
    public let error: Error?

    /// The info about the ad successfully obtained during the pre-bidding operation.
    public let adInfo: AdInfo?

    /// Internal constructor.
    init(error: Error?, adInfo: AdInfo?) {
        self.error = error
        self.adInfo = adInfo
    }

    /// Public constructor to create a result object with a APS `DTBAdResponse` object.
    /// Use this constructor when you succeed in loading an ad with the APS SDK.
    public convenience init(adResponse: DTBAdResponse) {
        let adInfo = AdInfo(
            pricePoint: adResponse.amznSlots(),
            bidPayload: adResponse.mediationHints()
        )
        self.init(error: nil, adInfo: adInfo)
    }

    /// Public constructor to create a result object with an error.
    /// Use this constructor when you fail to load an ad with the APS SDK.
    public convenience init(error: Error) {
        self.init(error: error, adInfo: nil)
    }

    /// Public constructor to create a result object from a `AdInfo` object.
    /// Generally `init(adResponse:)` should be used instead.
    public convenience init(adInfo: AdInfo) {
        self.init(error: nil, adInfo: adInfo)
    }
}
