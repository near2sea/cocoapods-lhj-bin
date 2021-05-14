# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-lhj-bin/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-aomi-bin'
  spec.version       = CBin::VERSION
  spec.authors       = ['lihaijian']
  spec.email         = ['sanan.li@qq.com']
  spec.description   = %q{A short description of cocoapods-lhj-bin.}
  spec.summary       = %q{A longer description of cocoapods-lhj-bin.}
  spec.homepage      = 'https://github.com/near2sea/cocoapods-lhj-bin'
  spec.license       = 'MIT'

  spec.files         = Dir["lib/**/*.rb","spec/**/*.rb","lib/**/*.plist"] + %w{README.md LICENSE.txt }
  # spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'cocoapods'
  spec.add_dependency 'cocoapods-generate', '~>2.0.1'
  spec.add_dependency 'parallel'
  spec.add_dependency 'aliyun-sdk', '~>0.8.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
