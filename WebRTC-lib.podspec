Pod::Spec.new do |spec|

  spec.name         = "WebRTC-lib"
  spec.version      = "149.0.0"
  spec.summary      = " A community-driven distribution of up to date WebRTC framework binaries for iOS and macOS."
  spec.description  = <<-DESC
  This pod contains community-driven distribution of WebRTC framework binaries for iOS and macOS.
  All binaries in this repository are compiled from the official WebRTC source code without any modifications to the sources code or to the output binaries.
  DESC

  spec.homepage     = "https://github.com/stasel/WebRTC"
  spec.license      = { :type => 'BSD', :file => 'WebRTC.xcframework/LICENSE' }
  spec.author       = "Stasel"
  spec.ios.deployment_target = '12.0'
  spec.osx.deployment_target = '10.11'

  spec.source       = { :http => "https://github.com/stasel/WebRTC/releases/download/149.0.0/WebRTC-M149.xcframework.zip" }
  spec.vendored_frameworks = "WebRTC.xcframework"
  
end
