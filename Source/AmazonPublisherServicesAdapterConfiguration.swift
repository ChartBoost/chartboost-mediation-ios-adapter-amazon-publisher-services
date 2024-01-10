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
}
