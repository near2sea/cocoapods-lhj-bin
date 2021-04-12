# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-lhj-bin/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-lhj-bin'
  spec.version       = CocoapodsLhjBin::VERSION
  spec.authors       = ['lihaijian']
  spec.email         = ['sanan.li@qq.com']
  spec.description   = %q{A short description of cocoapods-lhj-bin.}
  spec.summary       = %q{A longer description of cocoapods-lhj-bin.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-lhj-bin'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
