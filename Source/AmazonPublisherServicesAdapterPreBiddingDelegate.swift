
import DTBiOSSDK

// TODO: Comments

@objc
public protocol AmazonPublisherServicesAdapterPreBiddingDelegate: AnyObject {
    func onPreBid(
        request: AmazonPublisherServicesAdapterPreBidRequest,
        completion: @escaping (AmazonPublisherServicesAdapterPreBidResult) -> Void
    )
}

@objcMembers
public final class AmazonPublisherServicesAdapterPreBidRequest: NSObject {
    /// Chartboost Mediation's placement identifier.
    public let chartboostPlacement: String
    /// Ad format.
    public let format: String

    init(chartboostPlacement: String, format: String) {
        self.chartboostPlacement = chartboostPlacement
        self.format = format
    }
}

@objcMembers
public final class AmazonPublisherServicesAdapterPreBidResult: NSObject {

    @objc(AmazonPublisherServicesAdapterPreBidAdInfo)
    @objcMembers
    public final class AdInfo: NSObject {
        
        // TODO: Comments. Indicate exactly where to obtain the values from.
        let pricePoint: String

        /// Amazon mediation hints associated with `amazonPricePoint`.
        let mediationHints: [AnyHashable: Any]

        public init(pricePoint: String, mediationHints: [AnyHashable : Any]) {
            self.pricePoint = pricePoint
            self.mediationHints = mediationHints
        }
    }

    public let error: Error?

    public let adInfo: AdInfo?

    init(error: Error?, adInfo: AdInfo?) {
        self.error = error
        self.adInfo = adInfo
    }

    public convenience init(adResponse: DTBAdResponse) {
        let adInfo = AdInfo(
            pricePoint: adResponse.amznSlots(),
            mediationHints: adResponse.mediationHints()
        )
        self.init(error: nil, adInfo: adInfo)
    }

    public convenience init(adInfo: AdInfo) {
        self.init(error: nil, adInfo: adInfo)
    }

    public convenience init(error: Error) {
        self.init(error: error, adInfo: nil)
    }
}
