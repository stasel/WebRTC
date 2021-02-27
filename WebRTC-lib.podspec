Pod::Spec.new do |spec|

  spec.name         = "WebRTC-lib"
  spec.version      = "88.0.0"
  spec.summary      = "Unofficial distribution of WebRTC framework binaries for iOS. "
  spec.description  = <<-DESC
  This pod contains unofficial distribution of WebRTC framework binaries for iOS.
  All binaries in this repository are compiled from the official WebRTC source code without any modifications to the sources code or to the output binaries.
  DESC

  spec.homepage     = "https://github.com/stasel/WebRTC"
  spec.license      = { :type => 'BSD' }
  spec.author       = "Stasel"
  spec.platform     = :ios, "10.0"

  spec.source       = { :http => "https://github.com/stasel/WebRTC/releases/download/88.0.0/WebRTC-M88.xcframework.zip" }
  spec.vendored_frameworks = "WebRTC.xcframework"

  # spec.pod_target_xcconfig = { "ARCHS" => "$(ARCHS_STANDARD_64_BIT)" }

end
