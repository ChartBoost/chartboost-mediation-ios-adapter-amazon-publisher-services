// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK
import Foundation
import UIKit

/// Base class for Chartboost Mediation Amazon Publisher Services adapter ads.
class AmazonPublisherServicesAdapterAd: NSObject {
    
    /// The partner adapter that created this ad.
    var adapter: PartnerAdapter { amazonAdapter }

    /// The ad load request associated to the ad.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    let request: PartnerAdLoadRequest
    
    /// The partner ad delegate to send ad life-cycle events to.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    weak var delegate: PartnerAdDelegate?

    let amazonAdapter: AmazonPublisherServicesAdapter

    // TODO: Comments
    let bidPayload: [AnyHashable: Any]?

    /// The completion handler to notify Chartboost Mediation of ad show completion result.
    var loadCompletion: ((Result<PartnerEventDetails, Error>) -> Void)?

    /// The completion handler to notify Chartboost Mediation of ad load completion result.
    var showCompletion: ((Result<PartnerEventDetails, Error>) -> Void)?

    /// Create a new instance of the adapter.
    /// - Parameters:
    ///   - adapter: The current adapter instance
    ///   - request: The current AdLoadRequest containing data relevant to the curent ad request
    // TODO: Comments
    ///   - bidPayload:
    init(adapter: AmazonPublisherServicesAdapter, request: PartnerAdLoadRequest, delegate: PartnerAdDelegate, bidPayload: [AnyHashable: Any]?) {
        self.amazonAdapter = adapter
        self.request = request
        self.delegate = delegate
        self.bidPayload = bidPayload
    }
}
