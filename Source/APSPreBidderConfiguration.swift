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

extension APSPreBidderConfiguration {
    static func makeConfigurations(from jsonArray: [[String : Any]]) -> [APSPreBidderConfiguration]? {
        let decoder = JSONDecoder()
        var prebidderConfigurations = [APSPreBidderConfiguration]()
        jsonArray.forEach { json in
            guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
                return
            }
            guard let preBidSettings = try? decoder.decode(APSPreBidSettings.self, from: data) else {
                return
            }
            let settings = json["settings"] as? [String: Any]
            let configuration = preBidSettings.asAPSPreBidderConfiguration(settings: settings)
            prebidderConfigurations.append(configuration)
        }
        return prebidderConfigurations
    }
}
