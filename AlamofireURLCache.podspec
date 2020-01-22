#
# Be sure to run `pod lib lint AlamofireURLCache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AlamofireURLCache'
  s.version          = '0.4.0'
  s.summary          = 'The mirror of kenshincui/AlamofireURLCache which unsupported CocoaPods'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The mirror of AlamofireURLCache which unsupported CocoaPods
                       DESC

  s.homepage         = 'https://github.com/Jinkeycode/AlamofireURLCache'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jinkey' => 'jinkey@bytetalk.cn' }
  s.source           = { :git => 'https://github.com/Jinkeycode/AlamofireURLCache.git', :tag => s.version.to_s }
  s.social_media_url = 'https://jinkey.ai'

  s.ios.deployment_target = '8.0'
  s.swift_versions = ['5.0', '5.1']
  s.source_files = 'AlamofireURLCache/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AlamofireURLCache' => ['AlamofireURLCache/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'Alamofire', '~> 4.4'
end
