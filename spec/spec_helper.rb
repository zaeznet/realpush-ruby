begin
  require 'bundler/setup'
rescue LoadError
  puts 'although not required, it is recommended that you use bundler when running the tests'
end

# Run Coverage report
require 'simplecov'
SimpleCov.start do
  add_group 'Libraries', 'lib'
end

# Report to codeclimate
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require File.expand_path( '../../lib/realpush', __FILE__ )
require 'rspec'
require 'em-http' # As of webmock 1.4.0, em-http must be loaded first
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!
  end
end