// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import DTBiOSSDK

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AmazonPublisherServicesAdapterConfiguration: NSObject, PartnerAdapterConfiguration {
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        APS.version()
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the
    /// last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.
    /// <Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.4.10.0.0"

    /// The partner's unique identifier.
    @objc public static let partnerID = "amazon_aps"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "Amazon Publisher Services"

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool {
        get {
            DTBAds.sharedInstance().testMode
        }
        set {
            DTBAds.sharedInstance().testMode = newValue
            log("Test mode set to \(testMode)")
        }
    }

    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging = false {
        didSet {
            DTBAds.sharedInstance().setLogLevel(DTBLogLevelAll)
            log("Verbose logging set to \(verboseLogging)")
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
