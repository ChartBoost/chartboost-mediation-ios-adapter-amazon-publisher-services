// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A delegate that performs pre-bidding operations by integrating directly with the Amazon Publisher Services SDK.
/// Publishers are required to implement this delegate and set the property 
/// ``AmazonPublisherServicesAdapterConfiguration/preBiddingDelegate`` during app initialization.
///
/// Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
/// The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
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
