
Pod::Spec.new do |s|
  s.name             = "Pay360Payments"
  s.version          = "2.0.0"
  s.summary          = "Pay360 IOS SDK"
  s.description      = <<-DESC
                        # Pay360 IOS SDK
			Payments SDK For the Pay360 Payment service for use with IOS apps
			DESC
  s.homepage         = "https://github.com/pay360/mobilesdk-ios"
  s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.author           = { "Pay360" => "pay360completesupport@capita.co.uk"  }
  s.source           = { :git => "https://github.com/pay360/mobilesdk-ios.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = ['Pay360SDK/*.[mh]','Pay360SDK/*.h','Pay360SDK/Public/*.h']
  s.resource_bundles = {
    'Pay360Payments' => ['Pay360Resources/*','Pay360Library/PPOWebViewController.xib','Framework/Info.plist']
  }

  s.public_header_files = ['Pay360SDK/Public/*.h']
  s.frameworks = 'UIKit', 'SystemConfiguration', 'CoreGraphics'

end
