Pod::Spec.new do |s|

  s.name         = 'DITranquillityGraphViz'
  s.version      = '0.0.1'
  s.summary      = 'DITranquillityGraphViz - Plugin for visualization dependency graph'

  s.description  = <<-DESC
  					DITranquillityGraphViz - Plugin for visualization dependency graph use GraphAPI from DITranquillity.
            DESC

  s.homepage     = 'https://github.com/ivlevAstef/DITranquillityGraphViz'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.documentation_url = 'https://htmlpreview.github.io/?https://github.com/ivlevAstef/DITranquillityGraphViz/blob/master/Documentation/code/index.html'

  s.author       = { 'Alexander.Ivlev' => 'ivlev.stef@gmail.com' }
  s.source       = { :git => 'https://github.com/ivlevAstef/DITranquillityGraphViz.git', :tag => "v#{s.version}" }

  s.requires_arc = true
  s.swift_version = '5.1'

  s.dependency 'DITranquillity', '>= 4.1.0'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'

  s.source_files = 'Sources/**/*.{h,swift}'
  
end
