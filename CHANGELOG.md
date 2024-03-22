## Changelog

Note the first digit of every adapter version corresponds to the major version of the Chartboost Mediation SDK compatible with that adapter. 
Adapters are compatible with any Chartboost Mediation SDK version within that major version.

### 4.4.9.0.1
- Prevent `onPreBid(request:completion:)` delegate calls from being made for prebids without
an associated APS placement.
- This version of the adapter has been certified with AmazonPublisherServicesSDK 4.9.0.

### 4.4.9.0.0
- This version of the adapter has been certified with AmazonPublisherServicesSDK 4.9.0.

### 4.4.8.0.1
- Prevent `onPreBid(request:completion:)` delegate calls from being made for prebids without
an associated APS placement.
- This version of the adapter has been certified with AmazonPublisherServicesSDK 4.8.0.

### 4.4.8.0.0
- This version of the adapter has been certified with AmazonPublisherServicesSDK 4.8.0.

### 4.4.7.0.3
- Prevent `onPreBid(request:completion:)` delegate calls from being made for prebids without
an associated APS placement.
- This version of the adapter has been certified with AmazonPublisherServicesSDK 4.7.0.

### 4.4.7.0.2
- Chartboost is not permitted to wrap load or initialization calls for Amazon APS.
  Please review Amazon's documentation to initialize Amazon Publisher Services, implement a
  `AmazonPublisherServicesAdapterPreBiddingDelegate`, and set it on 
  `AmazonPublisherServicesAdapterConfiguration.preBiddingDelegate`.
- This version of the adapter has been certified with AmazonPublisherServicesSDK 4.7.0.

### 4.4.7.0.1
- Add support for Adaptive Banners.
- No longer performing console logging on iOS 11.
- This version of the adapters has been certified with AmazonPublisherServicesSDK 4.7.0.

### 4.4.7.0.0
- This version of the adapters has been certified with AmazonPublisherServicesSDK 4.7.0.

### 4.4.6.0.1
- Add support for Rewarded Video ad format.
- This version of the adapters has been certified with AmazonPublisherServicesSDK 4.6.0.

### 4.4.6.0.0
- This version of the adapters has been certified with AmazonPublisherServicesSDK 4.6.0.

### 4.4.5.6.1
- Add support for Rewarded Video ad format.
- This version of the adapters has been certified with AmazonPublisherServicesSDK 4.5.6.

### 4.4.5.6.0
- This version of the adapters has been certified with AmazonPublisherServicesSDK 4.5.6.
