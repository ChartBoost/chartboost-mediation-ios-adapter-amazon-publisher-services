//
//  APSPreBidderConfiguration.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//
//

import Foundation

/// Prebidder configuration.
struct APSPreBidderConfiguration {
    /// Amazon slot UUID associated with the Helium placement name.
    let amazonSlotUUID: String
    
    /// Bidder-specific configuration.
    let configuration: [String: Any]
    
    /// Ad format associated with the Amazon slot UUID.
    let format: APSAdFormat
    
    /// Helium placement name.
    let heliumPlacement: String
    
    init(heliumPlacement: String, amazonSlotUUID: String, format: APSAdFormat, configuration: [String: Any]?) {
        self.amazonSlotUUID = amazonSlotUUID
        self.configuration = configuration ?? [:]
        self.format = format
        self.heliumPlacement = heliumPlacement
    }
}
