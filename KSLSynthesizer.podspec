Pod::Spec.new do |s|
    s.name         = "KSLSynthesizer"
    s.version      = "0.5.0"
    s.summary      = "Audio Synthesizer & Sequencer engine for iOS."

    s.description  = <<-DESC
    KSLSynthesizer is a simple but precise audio sequencer engine for iOS.
    **This library uses a sample program contained in KORG WIST SDK.**
    DESC

    s.homepage     = "https://github.com/hirohitokato/KSLSynthesizer"
    #s.screenshots  = "https://raw.githubusercontent.com/hirohitokato/KSLSynthesizer/master/images/screenshots_1.gif"
    s.source       = { :git => "https://github.com/hirohitokato/KSLSynthesizer.git", :tag => "v#{s.version}" }

    s.license      = "New BSD"
    s.author       = "Hirohito Kato"
    s.social_media_url   = "http://twitter.com/hkato193"

    s.platform     = :ios
    s.ios.deployment_target = "8.0"

    s.requires_arc = true
    s.frameworks   = 'Foundation', 'AVFoundation', 'AudioToolbox'
    s.module_name  = "KSLSynthesizer"
    s.source_files = "KSLSynthesizer/**/*.{h,cpp,mm,swift}"
end