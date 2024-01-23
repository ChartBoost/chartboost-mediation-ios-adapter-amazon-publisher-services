// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import DTBiOSSDK

/// A delegate that performs pre-bidding operations by integrating directly with the Amazon Publisher Services SDK.
/// Publishers are required to implement this delegate and set the property 
/// ``AmazonPublisherServicesAdapterConfiguration/preBiddingDelegate`` during app initialization.
///
/// Prebidding feature is restricted for APS. Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
/// The adapter handles APS initialization and wrapped prebidding only when the managed prebidding flag is enabled.
/// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
@objc
public protocol AmazonPublisherServicesAdapterPreBiddingDelegate: AnyObject {

    /// Called by the Amazon Publishing Services adapter during pre-bidding, as part of the
    /// Chartboost ad load process.
    /// Here publishers should load an ad through the APS SDK, using the placement and format
    /// indicated in the `request` parameter, and returning a `result` object with the obtained
    /// APS `DTBAdResponse` info in the completion handler.
    /// - parameter request: A request model containing the info to be used to load the APS ad.
    /// - parameter completion: A completion handler to be executed at the end of the APS load
    /// operation. This handler should always get called, passing a result object instantiated
    /// with a `DTBAdResponse` object if successful, or with an error in case of failure.
    func onPreBid(
        request: AmazonPublisherServicesAdapterPreBidRequest,
        completion: @escaping (AmazonPublisherServicesAdapterPreBidResult) -> Void
    )
}

/// A request model containing the info to be used by publishers to load an APS ad during pre-bidding.
@objcMembers
public final class AmazonPublisherServicesAdapterPreBidRequest: NSObject {

    /// Chartboost Mediation's placement identifier.
    public let chartboostPlacement: String
    /// Ad format.
    public let format: String

    /// Internal constructor.
    init(chartboostPlacement: String, format: String) {
        self.chartboostPlacement = chartboostPlacement
        self.format = format
    }
}

/// A result model containing the ad info obtained by publishers at the end of an APS load during pre-bidding.
@objcMembers
public final class AmazonPublisherServicesAdapterPreBidResult: NSObject {

    /// APS Ad info obtained during pre-bidding.
    @objc(AmazonPublisherServicesAdapterPreBidAdInfo)
    @objcMembers
    public final class AdInfo: NSObject {
        
        /// The associated price point.
        /// Corresponds to `DTBAdResponse.amznSlots()`.
        let pricePoint: String

        /// The associated bid payload.
        /// Corresponds to `DTBAdResponse.mediationHints()`.
        let bidPayload: [AnyHashable: Any]

        /// Public constructor to create an ad info model.
        /// Generally ``AmazonPublisherServicesAdapterPreBidResult\init(adResponse:)`` should be used instead.
        public init(pricePoint: String, bidPayload: [AnyHashable : Any]) {
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
