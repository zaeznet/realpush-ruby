require 'spec_helper'

describe RealPush::API::App do
  data = {
      alias_name: 'APP 1',
      max_connections: '0',
      max_daily_messages: '0',
      status: 'active'
  }

  it 'should try exception when token has invalid format' do
    50.times do
      expect { RealPush::API::App.new( SecureRandom.urlsafe_base64(32, true) ) }.not_to raise_error
    end
    expect { RealPush::API::App.new( '' ) }.to           raise_error(RealPush::ConfigurationError)
    expect { RealPush::API::App.new( '@'+('2'*42) ) }.to raise_error(RealPush::ConfigurationError)
    expect { RealPush::API::App.new( 'a'*44 ) }.to       raise_error(RealPush::ConfigurationError)
  end

  describe 'Methods from base configuration' do

    let(:app) { RealPush::API::App.new( SecureRandom.urlsafe_base64(32, true) ) }

    it 'should accept the params in requests (alias_name, max_connections, max_daily_messages, status)' do
      [:alias_name, :max_connections, :max_daily_messages, :status].each do |p|
        expect(RealPush::API::App.params_accept.include? p).to eql true
      end
    end

    it 'should have a instance method to LIST all APPs' do
      expect(app.respond_to? :list).to be_truthy
    end

    it 'should have a instance method to DESTROY an app' do
      expect(app.respond_to? :destroy).to be_truthy
    end

    it 'should have a instance method to CREATE an app' do
      expect(app.respond_to? :create).to be_truthy
    end

    it 'should have a instance method to UPDATE an app' do
      expect(app.respond_to? :update).to be_truthy
    end

  end

  describe 'List method' do

    let(:app) { RealPush::API::App.new( SecureRandom.urlsafe_base64(32, true) ) }

    before do
      api_path = %r{apps\.json}
      stub_request(:get, api_path).
          with({
                   :headers => { 'X-RealPush-Token' => app.token }
               }).
          to_return({
                        :status => 200,
                        :body => MultiJson.encode([
                                                      {id: SecureRandom.hex(12)},
                                                      {id: SecureRandom.hex(12)},
                                                      {id: SecureRandom.hex(12)}
                                                  ])
                    })
    end

    it 'testing connection and requesting' do
      app.list
    end

    it 'should contains a tree elements in response' do
      list = app.list
      expect(list.count).to eql 3
    end

  end

  describe 'Destroy method' do

    let(:app) { RealPush::API::App.new( SecureRandom.urlsafe_base64(32, true) ) }

    before do
      api_path = %r{apps/123\.json}
      stub_request(:delete, api_path).
          with({
                   :headers => { 'X-RealPush-Token' => app.token }
               }).
          to_return({
                        :status => 204
                    })
    end

    it 'testing connection and requesting, with response 204' do
      app.destroy(123)
    end

  end

  describe 'Create method' do
    let(:app) { RealPush::API::App.new( SecureRandom.urlsafe_base64(32, true) ) }

    before do
      api_path = %r{apps\.json}
      stub_request(:post, api_path).
          with({
                   :headers => { 'X-RealPush-Token' => app.token },
                   :body => data
               }).
          to_return({
                        :status => 200,
                        body: MultiJson.encode( data.merge(id: SecureRandom.hex(12) ) )
                    })
    end

    it 'testing connection and requesting, with response 200' do
      app.create(data)
    end

    it 'must try exception when has invalid parameter' do
      expect {app.create({asd: 1}) }.to raise_error(RealPush::ConfigurationError)
    end

    it 'should returns a App data when successfully' do
      app_return = app.create(data).symbolize_keys
      data.keys.each { |key| expect(app_return.keys.include? key.to_sym).to be_truthy }
      expect(app_return[:id]).to be_truthy
    end

    it 'should returns error in Hash, when invalid data' do
      api_path = %r{apps\.json}
      stub_request(:post, api_path).
          with({
                   :headers => { 'X-RealPush-Token' => app.token }
               }).
          to_return({
                        :status => 500,
                        body: MultiJson.encode( { error: 'Message' } )
                    })
      app_return = app.create(data).symbolize_keys
      data.keys.each { |key| expect(app_return.keys.include? key.to_sym).to be_falsey }
      expect(app_return[:id]).to be_falsey
      expect(app_return[:error]).to be_truthy
    end

  end

  describe 'Update method' do
    let(:app) { RealPush::API::App.new( SecureRandom.urlsafe_base64(32, true) ) }

    before do
      api_path = %r{apps/123\.json}
      stub_request(:patch, api_path).
          with({
                   :headers => { 'X-RealPush-Token' => app.token },
                   :body => data
               }).
          to_return({
                        :status => 200,
                        body: MultiJson.encode( data.merge(id: 123 ) )
                    })
    end

    it 'testing connection and requesting, with response 200' do
      app.update(123, data)
    end

    it 'must try exception when has invalid parameter' do
      expect {app.update(123, {asd: 1}) }.to raise_error(RealPush::ConfigurationError)
    end

    it 'should returns a App data when successfully' do
      app_return = app.update(123, data).symbolize_keys
      data.keys.each { |key| expect(app_return.keys.include? key.to_sym).to be_truthy }
      expect(app_return[:id]).to be_truthy
    end

  end



end