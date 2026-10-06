#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_3d_map.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_3d_map'
  s.version          = '0.0.1'
  s.summary          = 'A cross-platform Flutter plugin for photorealistic 3D maps on Android and iOS.'
  s.description      = <<-DESC
A cross-platform Flutter plugin for photorealistic 3D maps on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/pushvindersingh/flutter_3d_map'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'three_d_map/Sources/three_d_map/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
