# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'verbal/version'

Gem::Specification.new do |spec|
  spec.name          = 'verbal'
  spec.version       = Verbal::VERSION
  spec.authors       = ['Zach Taylor']
  spec.email         = ['taylorzr@gmail.com']

  spec.summary       = 'Verb based class pattern'
  spec.homepage      = 'https://github.com/taylorzr/verbal'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'pry'
end
