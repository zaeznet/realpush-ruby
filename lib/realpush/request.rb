module RealPush
  class Request
    attr_reader :body, :params

    def initialize(client, verb, uri, params={}, body = nil)
      @client, @verb, @uri, @params = client, verb, uri, params

      raise ConfigurationError, "Invalid verb ('#{verb}')" unless %w{GET POST}.include? verb.to_s.upcase
      raise ConfigurationError, "Invalid client #{client.inspect}" unless client.is_a? Client
      raise ConfigurationError, "Invalid uri #{uri.inspect}" unless uri.is_a? URI

      @head = {}

      @body = body
      if body
        @params[:body_md5] = Digest::MD5.hexdigest(body)
        @head['Content-Type'] = 'application/json'
      end

      sign_params
    end

    def sign_params
      auth_hash = {
          :auth_version => "1.0",
          :auth_key => @client.app_id,
          :auth_timestamp => Time.now.to_i.to_s
      }
      params_string = auth_hash.sort.map do |k, v|
        "#{k}=#{v}"
      end.join('&')
      string_to_sign = [@verb.to_s.upcase, @uri.path, params_string].join "\n"
      digest = OpenSSL::Digest::SHA256.new
      auth_hash[:auth_signature] = OpenSSL::HMAC.hexdigest(digest, @client.privatekey, string_to_sign)
      @params = @params.merge(auth_hash)
    end
    private :sign_params

    def send_sync
      http = @client.sync_http_client

      begin
        response = http.request(@verb, @uri, @params, @body, @head)
      rescue HTTPClient::BadResponseError,
             HTTPClient::TimeoutError,
             SocketError,
             Errno::ECONNREFUSED => e
        raise RealPush::HTTPError, "#{e.message} (#{e.class})"
      end

      body = response.body ? response.body.chomp : nil

      return handle_response(response.code.to_i, body)
    end

    def send_async
      http = @client.sync_http_client
      http.request_async(@verb, @uri, @params, @body, @head)
    end

    private

    def handle_response(status_code, body)
      case status_code
        when 200
          return symbolize_first_level(MultiJson.decode(body))
        when 202
          return true
        when 400
          raise Error, "Bad request: #{body}"
        when 401
          raise AuthenticationError, body
        when 404
          raise Error, "404 Not found (#{@uri.path})"
        when 407
          raise Error, "Proxy Authentication Required"
        else
          raise Error, "Unknown error (status code #{status_code}): #{body}"
      end
    end

    def symbolize_first_level(hash)
      hash.inject({}) do |result, (key, value)|
        result[key.to_sym] = value
        result
      end
    end
  end
end