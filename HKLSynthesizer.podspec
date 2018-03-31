Pod::Spec.new do |s|
    s.name         = "HKLSynthesizer"
    s.version      = "0.9.0"
    s.summary      = "Audio Synthesizer & Sequencer engine for iOS."

    s.description  = <<-DESC
    HKLSynthesizer is a simple but precise audio synthesizer/sequencer engine for iOS.
    **This library uses a sample program contained in KORG WIST SDK.**
    DESC

    s.homepage     = "https://github.com/hirohitokato/HKLSynthesizer"
    s.screenshots  = "https://raw.githubusercontent.com/hirohitokato/HKLSynthesizer/master/images/screenshot_0.png"
    s.source       = { :git => "https://github.com/hirohitokato/HKLSynthesizer.git", :tag => "v#{s.version}" }

    s.license      = "New BSD"
    s.author       = "Hirohito Kato"
    s.social_media_url   = "http://twitter.com/hkato193"

    s.platform     = :ios
    s.ios.deployment_target = "10.3"

    s.requires_arc = true
    s.frameworks   = 'Foundation', 'AVFoundation', 'AudioToolbox'
    s.module_name  = "HKLSynthesizer"
    s.source_files = "HKLSynthesizer/**/*.{h,cpp,mm,swift}"
    s.public_header_files = ["HKLSynthesizer/HKLSynthesizer.h", "HKLSynthesizer/AudioEngine/AudioEngineIF.h"]
end
