#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'hovr_app_update'
  s.version          = '0.1.0'
  s.summary          = 'Native update-required dialog for HOVR Flutter apps.'
  s.description      = <<-DESC
Shows a native update prompt at most once per app process for HOVR rider and driver apps.
                       DESC
  s.homepage         = 'https://github.com/vishalsharma-hovr/hovr_app_update'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'HOVR' => 'dev@ridehovr.com' }
  s.source           = { :path => '.' }
  s.source_files = 'hovr_app_update/Sources/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.0'
  }
  s.swift_version = '5.0'
end
