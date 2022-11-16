//
//  APSPreBidderConfiguration.swift
//  ChartboostHeliumAdapterAmazonPublisherServices
//
//

import Foundation

/// Prebidder configuration.
struct APSPreBidderConfiguration: Codable {
    
    enum AdType: String, Codable {
        case interstitial
        case banner
    }
    
    /// Helium placement name.
    let heliumPlacement: String
    
    /// Amazon slot UUID associated with the Helium placement name.
    let partnerPlacement: String
        
    /// Ad format associated with the Amazon slot UUID.
    let type: AdType
    
    /// Indicates if this is a video placement.
    let video: Bool?
    
    /// Banner width.
    let width: Int?
    
    /// Banner height.
    let height: Int?
}

extension APSPreBidderConfiguration {
    
    static func makeConfiguration(from dictionary: [String: Any]) -> Self? {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            let configuration = try decoder.decode(APSPreBidderConfiguration.self, from: data)
            return configuration
        } catch {
            return nil
        }
    }
}
