require 'signature'
require 'multi_json'

module RealPush

  class Client

    attr_accessor :scheme, :app_id, :privatekey, :hostname, :port
    attr_writer :connect_timeout, :send_timeout, :receive_timeout,
                :keep_alive_timeout

    def initialize(options={})
      options = {
        port: 443,
        scheme: 'http',
        hostname: '127.0.0.1',
        app_id: nil,
        privatekey: nil
      }.merge options

      @encrypted = false

      @scheme, @app_id, @privatekey, @hostname, @port = options.values_at(
        :scheme, :app_id, :privatekey, :hostname, :port
      )

      # Default timeouts
      @connect_timeout = 5
      @send_timeout = 5
      @receive_timeout = 5
      @keep_alive_timeout = 30
    end

    def authenticate(publickey, privatekey)
      @app_id, @privatekey = publickey, privatekey
    end

    # Generate the expected response for an authentication endpoint.
    #
    # @example Private channels
    #   render :json => RealPush.default_client.authenticate(params[:realpush])
    #
    # @param custom_string [String | Hash]
    #
    # @return [Hash]
    def authentication_string(custom_string=nil)
      custom_string = MultiJson.encode(custom_string) if custom_string.kind_of?(Hash)
      unless custom_string.nil? || custom_string.kind_of?(String)
        raise Error, 'Custom argument must be a string'
      end

      string_to_sign = [app_id, custom_string].compact.map(&:to_s).join(':')
      digest = OpenSSL::Digest::SHA256.new
      signature = OpenSSL::HMAC.hexdigest(digest, privatekey, string_to_sign)
      {auth:signature}
    end

    # @private Returns the authentication token for the client
    def authentication_token
      Signature::Token.new(app_id, privatekey)
    end

    def config(&block)
      raise ConfigurationError, 'You need a block' unless block_given?
      yield self
    end

    def encrypted=(bool)
      @scheme = bool ? 'https' : 'http'
      # Configure port if it hasn't already been configured
      @port = bool ? 443 : 80
    end

    def encrypted?
      scheme == 'https'
    end

    def get(path, params)
      Resource.new(self, "/#{app_id}#{path}").get params
    end

    def get_async(path, params)
      Resource.new(self, "/#{app_id}#{path}").get_async params
    end

    def post(path, body)
      Resource.new(self, "/#{app_id}#{path}").post body
    end

    def post_async(path, body)
      Resource.new(self, "/#{app_id}#{path}").post_async body
    end

    # @private Construct a net/http http client
    def sync_http_client
      @client ||= begin
        require 'httpclient'

        HTTPClient.new(default_header: {'X-RealPush-Secret-Key' => @privatekey}).tap do |c|
          c.connect_timeout = @connect_timeout
          c.send_timeout = @send_timeout
          c.receive_timeout = @receive_timeout
          c.keep_alive_timeout = @keep_alive_timeout
        end
      end
    end

    # Convenience method to set all timeouts to the same value (in seconds).
    # For more control, use the individual writers.
    def timeout=(value)
      @connect_timeout, @send_timeout, @receive_timeout = value, value, value
    end

    # Trigger an event on one or more channels
    #
    # POST /api/[api_version]/events/[event_name]/
    #
    # @param channels [String or Array] 1-10 channel names
    # @param event_name [String]
    # @param data [Object] Event data to be triggered in javascript.
    #   Objects other than strings will be converted to JSON
    #
    # @return [Hash] See Thunderpush API docs
    #
    # @raise [ThunderPush::Error] Unsuccessful response - see the error message
    # @raise [ThunderPush::HTTPError] Error raised inside http client. The original error is wrapped in error.original_error
    #
    def trigger(channels, event_name, data)
      post("/events/#{event_name}/", trigger_params(channels, data))
    end

    # Trigger an event on one or more channels
    #
    # POST /apps/[app_id]/events/[event_name]/
    #
    # @param channels [String or Array] 1-10 channel names
    # @param event_name [String]
    # @param data [Object] Event data to be triggered in javascript.
    #   Objects other than strings will be converted to JSON
    #
    # @raise [ThunderPush::Error] Unsuccessful response - see the error message
    # @raise [ThunderPush::HTTPError] Error raised inside http client. The original error is wrapped in error.original_error
    #
    def trigger_async(channels, event_name, data)
      post_async("/events/#{event_name}/", trigger_params(channels, data))
    end

    # Configure Thunderpush connection by providing a url rather than specifying
    # scheme, key, secret, and app_id separately.
    #
    # @example
    #   ThunderPush.default_client.url = http://key:secret@127.0.0.1:5678
    #
    def url=(str)
      regex = /^(?<scheme>http|https):\/\/((?<app_id>[\d-]+)(:(?<privatekey>[\w-]+){1})?@)?(?<hostname>[\w\.-]+)(:(?<port>[\d]+))?/
      match = str.match regex
      @scheme     = match[:scheme]     unless match[:scheme].nil?
      self.encrypted= true if scheme == 'https'
      @port       = match[:port].to_i  unless match[:port].nil?
      @hostname   = match[:hostname]   unless match[:hostname].nil?
      @app_id     = match[:app_id]     unless match[:app_id].nil?
      @privatekey = match[:privatekey] unless match[:privatekey].nil?
    end

    # @private Builds a url for this app, optionally appending a path
    def url(path = '')
      path = "/#{path}" unless path.start_with? '/'
      URI::Generic.build({
        :scheme => @scheme,
        :host => @hostname,
        :port => @port,
        :path => "/#{RealPush::API_VERSION_APP}#{path}"
      })
    end

    protected

    def trigger_params(channels, data)
      data.merge! :channels => channels
      begin
        MultiJson.encode(data)
      rescue MultiJson::DecodeError => e
        ThunderPush.logger.error("Could not convert #{data.inspect} into JSON")
        raise e
      end
    end
  end
end