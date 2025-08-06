// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation

/// A request model containing the info to be used by publishers to load an APS ad during pre-bidding.
///
/// Chartboost is not permitted to wrap the Amazon APS initialization or bid request methods directly.
/// The adapter handles APS initialization and prebidding only when the managed prebidding flag is enabled.
/// For more information please contact the Amazon APS support team at https://aps.amazon.com/aps/contact-us/
@objcMembers
public final class AmazonPublisherServicesAdapterPreBidRequest: NSObject {
    @objc(AmazonPublisherServicesAdapterPreBidRequestPartnerSettings)
    @objcMembers
    public final class AmazonSettings: NSObject {
        /// Amazon slot UUID associated with the Chartboost Mediation placement name.
        public let partnerPlacement: String

        /// Indicates if this is a video placement.
        public let video: Bool

        /// Banner width.
        public let width: Int

        /// Banner height.
        public let height: Int

        /// Internal constructor.
        init(partnerPlacement: String, video: Bool?, width: Int?, height: Int?) {
            self.partnerPlacement = partnerPlacement
            self.video = video ?? false
            self.width = width ?? 0
            self.height = height ?? 0
        }

        /// Internal constructor to instantiate the model from the credentials dictionary obtained from the SDK.
        convenience init?(dictionary: [String: Any]) {
            guard let partnerPlacement = dictionary["partner_placement"] as? String else {
                return nil
            }
            self.init(
                partnerPlacement: partnerPlacement,
                video: dictionary["video"] as? Bool,
                width: dictionary["width"] as? Int,
                height: dictionary["height"] as? Int
            )
        }
    }

    /// Chartboost Mediation's placement identifier.
    public let mediationPlacement: String

    /// Ad format.
    /// Refer to the constants defined in PartnerAdFormats for possible values.
    public let format: PartnerAdFormat

    /// Ad size. `nil` for full-screen ads.
    public let bannerSize: BannerSize?

    /// Amazon-specific info needed to load the APS ad.
    public let amazonSettings: AmazonSettings

    /// Key-value pairs to be associated with the placement.
    public let keywords: [String: String]

    /// Internal constructor.
    init(mediationPlacement: String, format: String, bannerSize: BannerSize?, amazonSettings: AmazonSettings, keywords: [String: String]) {
        self.mediationPlacement = mediationPlacement
        self.format = format
        self.bannerSize = bannerSize
        self.amazonSettings = amazonSettings
        self.keywords = keywords
    }
}
