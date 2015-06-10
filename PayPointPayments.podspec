#
# Be sure to run `pod lib lint TestPod.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PayPointPayments"
  s.version          = "1.0.0-BETA"
  s.summary          = "PayPoint IOS SDK"
  s.description      = <<-DESC
                        # PayPoint IOS SDK 
			Payments SDK For the PayPoint Payment service for use with IOS apps
			DESC
  s.homepage         = "https://github.com/paypoint/PayPointIOSSDK"
  s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "PayPoint" => "product@paypoint.net"  }
  s.source           = { :git => "https://github.com/paypoint/PayPointIOSSDK.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true


  s.source_files = ['PaypointSDK/*.[mh]','PaypointLibrary/*.h']
  s.resource_bundles = {
    'PayPointIOSSDK' => ['PaypointResources/*']
  }

  s.public_header_files = 'PaypointLibrary/*.h'
  s.frameworks = 'UIKit', 'SystemConfiguration', 'CoreGraphics'
  # s.dependency 'AFNetworking', '~> 2.3'
end
