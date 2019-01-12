Pod::Spec.new do |s|
    s.name         = "HKLStepSequencer"
    s.version      = "0.9.1"
    s.summary      = "A simple but precise step sequencer engine for iOS."

    s.description  = <<-DESC
    HKLStepSequencer is a simple but precise audio step sequencer engine for iOS.
    **This library uses a sample program contained in KORG WIST SDK.**
    DESC

    s.homepage     = "https://github.com/hirohitokato/HKLStepSequencer"
    s.screenshots  = "https://raw.githubusercontent.com/hirohitokato/HKLStepSequencer/master/images/screenshot_0.png"
    s.source       = { :git => "https://github.com/hirohitokato/HKLStepSequencer.git", :tag => "v#{s.version}" }

    s.license      = "New BSD"
    s.author       = "Hirohito Kato"
    s.social_media_url   = "https://github.com/hirohitokato"

    s.platform     = :ios
    s.ios.deployment_target = "10.0"

    s.requires_arc = true
    s.frameworks   = 'Foundation', 'AVFoundation', 'AudioToolbox'
    s.module_name  = "HKLStepSequencer"
    s.source_files = "HKLStepSequencer/**/*.{h,cpp,mm,swift}"
end
