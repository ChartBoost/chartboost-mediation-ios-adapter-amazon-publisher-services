//
//  AmazonPublisherServicesAdapterConfiguration.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import DTBiOSSDK

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AmazonPublisherServicesAdapterConfiguration: NSObject {
    
    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool = false {
        didSet {
            DTBAds.sharedInstance().testMode = testMode
            print("Amazon Publishing Services SDK test mode set to \(testMode)")
        }
    }
    
    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging: Bool = false {
        didSet {
            DTBAds.sharedInstance().setLogLevel(DTBLogLevelAll)
            print("Amazon Publishing Services SDK verbose logging set to \(verboseLogging)")
        }
    }
}
