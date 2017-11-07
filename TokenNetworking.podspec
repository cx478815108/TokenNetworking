Pod::Spec.new do |s|
    s.name         = 'TokenNetworking'
    s.version      = '1.0.1'
    s.summary      = 'An easy way to use network and write chainable methods'
    s.homepage     = 'https://github.com/cx478815108/TokenNetworking'
    s.license      = 'MIT'
    s.authors      = {'cx478815108' => 'feelings0811@wutnews.net'}
    s.platform     = :ios, '8.0'
    s.source       = {:git => 'https://github.com/cx478815108/TokenNetworking.git', :tag => 'v1.0.1'}
    s.source_files = 'TokenNetworking/**/*.{h,m}'
    s.requires_arc = true
end