require 'spec_helper'

describe RealPush::Client do

  before do
    @client1 = RealPush::Client.new

    @client2 = RealPush::Client.new
    @client2.app_id = '123456'
    @client2.privatekey = 'privatekey'
    @client2.hostname = 'localhost'
    @client2.scheme = 'https'
    @client2.port = 1123
  end

  it 'should return the url without app_id and private key informations' do
    @client1.url = 'http://123456:private@127.0.0.1:5678'
    expect(@client1.url.to_s).to eq 'http://127.0.0.1:5678/v1/'
  end

  it 'should return net/http object from sync_http_client' do
    expect(@client1.sync_http_client).to be_kind_of HTTPClient
  end

  it 'should be able configure from config and block' do
    expect { @client1.config }.to raise_error RealPush::ConfigurationError
    old_port = @client1.port
    @client1.config do |config|
      config.port = 111
    end
    expect(@client1.port).not_to eq old_port
  end

  describe 'different instances' do
    it 'should send scheme messages to different objects' do
      expect(@client1.scheme).not_to eq @client2.scheme
    end

    it 'should send app_id messages to different objects' do
      expect(@client1.app_id).not_to eq @client2.app_id
    end

    it 'should send privatekey messages to different objects' do
      expect(@client1.privatekey).not_to eq @client2.privatekey
    end

    it 'should send hostname messages to different objects' do
      expect(@client1.hostname).not_to eq @client2.hostname
    end

    it 'should send port messages to different objects' do
      expect(@client1.port).not_to eq @client2.port
    end

    it 'should send encrypted messages to different objects' do
      @client1.encrypted = false
      @client2.encrypted = true
      expect(@client1.scheme).not_to eq @client2.scheme
      expect(@client1.port).not_to eq @client2.port
    end
  end

  describe 'default configuration' do
    it 'should be preconfigured for api host' do
      expect(@client1.hostname).to eq '127.0.0.1'
    end

    it 'should be preconfigured for port 80' do
      expect(@client1.port).to eq 443
    end

    it 'should use standard logger if no other logger if defined' do
      RealPush.logger.debug('foo')
      expect(RealPush.logger).to be_kind_of(Logger)
    end
  end

  describe 'logging configuration' do
    it "can be configured to use any logger" do
      logger = double("ALogger")
      expect(logger).to receive(:debug).with('foo')
      RealPush.logger = logger
      RealPush.logger.debug('foo')
      RealPush.logger = nil
    end
  end

  describe 'configuration using url' do
    it 'should be possible to configure everything by setting the url' do
      @client1.url = 'http://123456789:private@127.0.0.1:5678'
      expect(@client1.scheme).to eq 'http'
      expect(@client1.app_id).to eq '123456789'
      expect(@client1.privatekey).to eq 'private'
      expect(@client1.hostname).to eq '127.0.0.1'
      expect(@client1.port).to eq 5678
    end

    it 'should override scheme and port when setting encrypted=true after url' do
      @client1.url = 'http://secret@127.0.0.1:5678'
      @client1.encrypted = true

      expect(@client1.scheme).to eq 'https'
      expect(@client1.port).to eq 443
    end

    it "should fail on bad urls" do
      expect { @client1.url = "gopher/somekey:somesecret@://127.0.0.1://m:8080" }.to raise_error
    end
  end

  describe 'trigger events do server' do

    it 'should be able trigger a event to RealPush server' do
      @client1.authenticate 'api_id', 'apisecret'
      api_path = %r{/api_id/events/event-name/}

      stub_request(:post, api_path).
      with({
              :headers => { 'X-RealPush-Secret-Key' => 'apisecret' }
          }).
      to_return({
        :status => 202
      })
      @client1.trigger ['channel-name'], 'event-name', {data: 'content'}
    end

  end

  describe 'Private commands' do
    expect_hash = {auth:'70bb4f429346ba2287bca93b4c9cd9cc1d29c00c76d0ecf6b5bc44c7cc0f67f7'}

    it 'authentication token to private subscribe from string' do
      @client1.authenticate 'apikey', 'apisecret'
      body = MultiJson.encode({data:{}, channel: 'private-channel'})
      expect(@client1.authentication_string body).to eq expect_hash
    end

    it 'authentication token to private subscribe from hash' do
      @client1.authenticate 'apikey', 'apisecret'
      body = {data:{}, channel: 'private-channel'}
      expect(@client1.authentication_string body).to eq expect_hash
    end

  end

end