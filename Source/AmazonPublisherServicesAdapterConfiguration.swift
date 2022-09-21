//
//  AmazonPublisherServicesAdapterConfiguration.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//

import DTBiOSSDK

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
public class AmazonPublisherServicesAdapterConfiguration {

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    public static var testMode: Bool = false {
        didSet {
            DTBAds.sharedInstance().testMode = testMode
        }
    }
    
    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    public static var verboseLogging: Bool = false {
        didSet {
            DTBAds.sharedInstance().setLogLevel(DTBLogLevelAll)
        }
    }
    
    /// Append any other properties that publishers can configure.
}
