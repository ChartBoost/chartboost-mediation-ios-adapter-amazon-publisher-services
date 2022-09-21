//
//  APSPreBidSettings.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//
//

import Foundation
import HeliumSdk
import DTBiOSSDK

/// Prebidder settings sent in during setup within the adapter configuration.  This struct only contains the decodable
/// bits and not the `settings` key since it is a `[String: Any]`.  `settings` is dealt with in a later stage
/// during construction of the `APSPreBidderConfiguration` structure that is actually used by the
/// `APSPreBiddingController` instance in the adapter.
struct APSPreBidSettings: Decodable {
    /// Helium ad type (as an integer) associated with the pre-bid settings.
    let heliumAdType: Int

    /// Helium placement identifier.
    let heliumPlacement: String

    /// The network placement identifier.
    let networkPlacement: String
}

extension APSPreBidSettings {
    var heliumAdTypeEnum: AdType {
        AdType(rawValue: heliumAdType) ?? .unselected
    }
}

extension APSPreBidSettings {
    func asAPSPreBidderConfiguration(settings: [String: Any]?) -> APSPreBidderConfiguration {
        let format: APSAdFormat = heliumAdTypeEnum == .banner ? .banner : .interstitial
        return APSPreBidderConfiguration(heliumPlacement: heliumPlacement, amazonSlotUUID: networkPlacement, format: format, configuration: settings)
    }
}
