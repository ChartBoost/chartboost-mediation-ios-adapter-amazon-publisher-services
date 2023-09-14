// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Prebidder configuration.
struct APSPreBidderConfiguration: Codable {
    
    enum AdType: String, Codable {
        case interstitial
        case banner
        case rewarded
        case adaptiveBanner = "adaptive_banner"
    }
    
    /// Chartboost Mediation placement name.
    let chartboostPlacement: String?

    /// Legacy Chartboost Mediation (Helium) placement name for compatibility with backend schema.
    /// We should be able to remove this once backend is updated.
    let heliumPlacement: String?
    
    /// Amazon slot UUID associated with the Chartboost Mediation placement name.
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
