// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import DTBiOSSDK
import os.log

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AmazonPublisherServicesAdapterConfiguration: NSObject {
    
    private static let log = OSLog(subsystem: "com.chartboost.mediation.adapter.amazon_aps", category: "Configuration")

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool = false {
        didSet {
            DTBAds.sharedInstance().testMode = testMode
            if #available(iOS 12.0, *) {
                os_log(.debug, log: log, "Amazon Publishing Services SDK test mode set to %{public}s", "\(testMode)")
            }
        }
    }
    
    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging: Bool = false {
        didSet {
            DTBAds.sharedInstance().setLogLevel(DTBLogLevelAll)
            if #available(iOS 12.0, *) {
                os_log(.debug, log: log, "Amazon Publishing Services SDK verbose logging set to %{public}s", "\(verboseLogging)")
            }
        }
    }

    /// A delegate that performs pre-bidding operations by integrating directly with the Amazon Publisher Services SDK.
    /// Publishers are required to implement the `AmazonPublisherServicesAdapterPreBiddingDelegate` delegate and set this
    /// property during app initialization.
    ///
    /// Prebidding feature is restricted for APS. Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
    /// The adapter handles APS initialization and wrapped prebidding only when the managed prebidding flag is enabled.
    /// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
    @objc public static var preBiddingDelegate: AmazonPublisherServicesAdapterPreBiddingDelegate? {
        get { AmazonPublisherServicesAdapter.preBiddingDelegate }
        set { AmazonPublisherServicesAdapter.preBiddingDelegate = newValue }
    }
}
