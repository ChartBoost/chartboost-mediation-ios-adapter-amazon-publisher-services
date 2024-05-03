// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import DTBiOSSDK
import os.log

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AmazonPublisherServicesAdapterConfiguration: NSObject {
    
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        APS.version()
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.4.9.0.1"

    /// The partner's unique identifier.
    @objc public static let partnerID = "amazon_aps"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "Amazon Publisher Services"

    private static let log = OSLog(subsystem: "com.chartboost.mediation.adapter.amazon_aps", category: "Configuration")

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool {
        get {
            DTBAds.sharedInstance().testMode
        }
        set {
            DTBAds.sharedInstance().testMode = newValue
            os_log(.debug, log: log, "Amazon Publishing Services SDK test mode set to %{public}s", "\(testMode)")
        }
    }
    
    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging: Bool = false {
        didSet {
            DTBAds.sharedInstance().setLogLevel(DTBLogLevelAll)
            os_log(.debug, log: log, "Amazon Publishing Services SDK verbose logging set to %{public}s", "\(verboseLogging)")
        }
    }

    /// A delegate that performs pre-bidding operations by integrating directly with the Amazon Publisher Services SDK.
    /// Publishers are required to implement the `AmazonPublisherServicesAdapterPreBiddingDelegate` delegate and set this
    /// property during app initialization.
    ///
    /// Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
    /// The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
    /// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
    @objc public static var preBiddingDelegate: AmazonPublisherServicesAdapterPreBiddingDelegate? {
        get { AmazonPublisherServicesAdapter.preBiddingDelegate }
        set { AmazonPublisherServicesAdapter.preBiddingDelegate = newValue }
    }
}
