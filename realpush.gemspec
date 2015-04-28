# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'realpush/version'

Gem::Specification.new do |spec|
  spec.name          = 'realpush'
  spec.version       = RealPush::VERSION
  spec.authors       = ['Zaez Team']
  spec.email         = ['contato@zaez.net']
  spec.summary       = %q{Library of integration with RealPush system. Written in Ruby.}
  spec.description   = %q{RealPush is a private and commercial system to send notifications via websocket.
The system allows the creation of applications based on its quota through access API.
Sending notifications to trigger customers with private and public channels. Synchronous and asynchronous requests..}
  spec.homepage      = 'http://realpush.cc/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'multi_json', '~> 1.0'
  spec.add_dependency 'httpclient', '~> 2.6'
  spec.add_dependency 'signature', '~> 0.1.6'
  spec.add_dependency 'activesupport', '>= 4'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rspec',   '~> 3.1.0'
  spec.add_development_dependency 'pry',     '>= 0.9.12'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'growl'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'em-http-request', '~> 1.1.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
