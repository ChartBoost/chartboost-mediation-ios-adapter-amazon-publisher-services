Pod::Spec.new do |spec|
  spec.name        = 'ChartboostHeliumAdapterAmazonPublisherServices'
  spec.version     = '4.4.4.2.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/helium-ios-adapter-chartboost'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Helium iOS SDK Amazon Publisher Services adapter.'
  spec.description = 'Amazon Publisher Services Adapters for mediating through Helium. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'HeliumAdapterAmazonPublisherServices'
  spec.source       = { :git => 'https://github.com/ChartBoost/helium-ios-adapter-amazon-publisher-services.git', :tag => '#{spec.version}' }
  spec.source_files = 'Source/**/*.{swift}'

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']
  
  # This adapter is compatible with all Helium 4.X versions of the SDK.
  spec.dependency 'ChartboostHelium', '~> 4.0'

  # Partner network SDK and version that this adapter is certified to work with.
  spec.dependency 'AmazonPublisherServicesSDK', '4.4.2' 

  # Indicates, that if use_frameworks! is specified, the pod should include a static library framework.
  spec.static_framework = true
end
