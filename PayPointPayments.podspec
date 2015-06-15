
Pod::Spec.new do |s|
  s.name             = "PayPointPayments"
  s.version          = "1.0.0-rc1"
  s.summary          = "PayPoint IOS SDK"
  s.description      = <<-DESC
                        # PayPoint IOS SDK 
			Payments SDK For the PayPoint Payment service for use with IOS apps
			DESC
  s.homepage         = "https://github.com/paypoint/PayPointIOSSDK"
  s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "PayPoint" => "product@paypoint.net"  }
  s.source           = { :git => "https://github.com/paypoint/PayPointIOSSDK.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = ['PaypointSDK/*.[mh]','PaypointLibrary/*.h']
  s.resource_bundles = {
    'PayPointPayments' => ['PaypointResources/*','PaypointLibrary/PPOWebViewController.xib']
  }

  s.public_header_files = ['PaypointLibrary/*.h','PaypointSDK/PPO*.h'] 
  s.frameworks = 'UIKit', 'SystemConfiguration', 'CoreGraphics'

end
