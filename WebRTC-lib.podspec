Pod::Spec.new do |spec|

  spec.name         = "WebRTC-lib"
  spec.version      = "130.0.0"
  spec.summary      = "Unofficial distribution of WebRTC framework binaries for iOS. "
  spec.description  = <<-DESC
  This pod contains unofficial distribution of WebRTC framework binaries for iOS.
  All binaries in this repository are compiled from the official WebRTC source code without any modifications to the sources code or to the output binaries.
  DESC

  spec.homepage     = "https://github.com/stasel/WebRTC"
  spec.license      = { :type => 'BSD', :file => 'WebRTC.xcframework/LICENSE' }
  spec.author       = "Stasel"
  spec.ios.deployment_target = '12.0'
  spec.osx.deployment_target = '10.11'

  spec.source       = { :http => "https://github.com/stasel/WebRTC/releases/download/130.0.0/WebRTC-M130.xcframework.zip" }
  spec.vendored_frameworks = "WebRTC.xcframework"
  
end
