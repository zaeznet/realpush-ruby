require 'spec_helper'

describe RealPush::Request do
  before do
    @client = RealPush.default_client
    @client.authenticate 'key', 'secret'
  end

  describe 'parameters in initializer' do
    it 'should give error when client parameter is not RealPush::Client' do
      expect { RealPush::Request.new(@client, 'GET', @client.url, {}) }.not_to raise_error
      expect { RealPush::Request.new('client', 'GET', @client.url, {}) }.to raise_error(RealPush::ConfigurationError)
    end

    it 'should receive GET or POST parameter in the verb' do
      expect { RealPush::Request.new(@client, 'GET', @client.url, {}) }.not_to raise_error
      expect { RealPush::Request.new(@client, 'POST', @client.url, {}) }.not_to raise_error
      expect { RealPush::Request.new(@client, 'PATH', @client.url, {}) }.to raise_error(RealPush::ConfigurationError)
    end

    it 'should give error when uri parameter is not URI' do
      expect { RealPush::Request.new(@client, 'GET', @client.url, {}) }.not_to raise_error
      expect { RealPush::Request.new(@client, 'GET', '', {}) }.to raise_error(RealPush::ConfigurationError)
    end

  end

  describe 'verbs request' do
    it 'should be able to send a GET request' do
      api_path = %r{/key/channels/channel-name/}
      stub_request(:get, api_path).
        with({
               :headers => {'X-RealPush-Secret-Key' => 'secret'},
               :query => hash_including({'auth_key'=>'key'})
             }).
        to_return(:status => 202)
      RealPush::Request.new(@client, 'GET', @client.url('key/channels/channel-name/'), {}).send_sync
    end

    it 'should be able to send a POST request' do
      api_path = %r{/key/channels/channel-name/}
      stub_request(:post, api_path).
        with({
               :headers => {'X-RealPush-Secret-Key' => 'secret'},
               :body => {foo: 'bar'}
             }).
        to_return(:status => 202)
      RealPush::Request.new(@client, 'POST', @client.url('key/channels/channel-name/'), {}, MultiJson.encode({foo: 'bar'})).send_sync
    end
  end

end