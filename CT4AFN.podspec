Pod::Spec.new do |s|
  s.name         = 'CT4AFN'
  s.version      = '0.1.4'
  s.summary      = 'Code encapsulation for AFNetworking'
  s.homepage     = 'https://github.com/Chan4iOS/CT4AFNetworking'
  s.author       = "CT4 => 284766710@qq.com"
  s.source       = {:git => 'https://github.com/Chan4iOS/CT4AFNetworking.git', :tag => "V#{s.version}"}

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = "CT4AFN/**/*.{h,m}"
  s.requires_arc = true
  s.libraries = 'z'
  s.dependency 'AFNetworking', '~> 3'
  s.license = 'MIT'
  s.frameworks = 'UIKit','AssetsLibrary','AVFoundation'

end
