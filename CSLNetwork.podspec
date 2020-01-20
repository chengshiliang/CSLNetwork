Pod::Spec.new do |s|
  s.name         = 'CSLNetwork'
  s.version      = '0.0.6'
  s.summary      = 'network include get post download upload file base afn 3.0'
  s.homepage     = 'https://github.com/chengshiliang/CSLNetwork'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'chengshiliang' => '285928582@qq.com' }
  s.source       = { :git => 'https://github.com/chengshiliang/CSLNetwork.git', :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.source_files = 'CSLNetwork/*.{h,m}'
  s.source_files = 'CSLNetwork/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit'
  s.dependency 'AFNetworking'
end