 Pod::Spec.new do |s|
   s.name         = 'ThoMoNetworking'
   s.version      = '1.0.0'
   s.summary      = 'Simple Networking for Your Cocoa and iPhone Apps - Out of the Box'
   s.homepage     = 'https://github.com/xlc/ThoMoNetworking'
   s.license      = 'MIT'
   s.author       = { 'Thorsten Karrer' => 'karrer@cs.rwth-aachen.de',
                      'Moritz Wittenhagen' => 'wittenhagen@cs.rwth-aachen.de',
                      'Xiliang Chen' => 'xlchen1291@gmail.com' }
   s.source       = { :git => 'https://github.com/xlc/ThoMoNetworking.git', :tag => '1.0.0' }
   s.source_files = 'Classes/**/*'
   s.private_header_files = '*Private.h'

   s.requires_arc = true

   s.ios.deployment_target = '6.0'
   s.osx.deployment_target = '10.8'
 end
