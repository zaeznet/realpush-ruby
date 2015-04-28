require 'multi_json'

module RealPush
  module API
    module Base
      extend ActiveSupport::Concern

      def self.included(base)
        base.class_eval do

          attr_reader :token

          attr_accessor :connect_timeout, :send_timeout, :receive_timeout, :keep_alive_timeout

          def initialize(token)
            raise ConfigurationError, "Invalid token format: #{token}" if /^[-=\w]{43}={0,2}$/.match(token).nil?
            @token = token
            @params_accept = []

            # Default timeouts
            @connect_timeout = 5
            @send_timeout = 5
            @receive_timeout = 5
            @keep_alive_timeout = 30
          end

          protected

          # Sends a request to the specified URL.
          #
          # @param method [String | Symbol]
          #     HTTP method to be sent.  method.to_s.upcase is used.
          #
          # @param uri [String | URI]
          #     HTTP method to be sent.  method.to_s.upcase is used.
          #
          # @param query [Hash]
          #     a Hash of query part of URL.
          #     e.g. { "a" => "b" } => 'http://host/part?a=b'
          #
          # @param body [Hash]
          #      a Hash of body part. e.g.
          #      { "a" => "b" } => 'a=b'
          #
          # @param header [Hash]
          #     a Hash of extra headers.  e.g.
          #     { 'Accept' => 'text/html' }.
          #
          # @return [ HTTP::Message ]
          def execute(method, uri, query={}, body={}, header={})
            begin
              response = httpclient.request(method, uri, query, body, header)
            rescue HTTPClient::BadResponseError,
                HTTPClient::TimeoutError,
                SocketError,
                Errno::ECONNREFUSED => e
              raise RealPush::HTTPError, "#{e.message} (#{e.class})"
            end
          end

          # TODO: nodoc
          # @return [HTTPClient]
          def httpclient
            @client ||= begin
              require 'httpclient'

              HTTPClient.new(default_header: {'X-RealPush-Token' => token}).tap do |c|
                c.connect_timeout = connect_timeout
                c.send_timeout = send_timeout
                c.receive_timeout = receive_timeout
                c.keep_alive_timeout = keep_alive_timeout
              end
            end
          end

          # Capture the contents of the request and makes the JSON parse inside the BODY content.
          #
          # @param content [ HTTP::Message ]
          #   Returns of self.httpclient
          #
          # @return [ Hash ]
          def parse_content(content)
            MultiJson.decode(content.body)
          end

          # Prepare the URL to the request, it contains the url pattern for API Version 1.0.
          #
          # :example:
          #   url()                //=> https://app.realpush.cc/api/v1/
          #   url('apps/123.json') //=> https://app.realpush.cc/api/v1/apps/123.json
          #
          # @param path [String]
          #   Added in path of URL
          #
          # @return [URI]
          def url(path='')
            path = "/#{path}" unless path.start_with? '/'
            URI::Generic.build({
                                   :scheme => 'https',
                                   :host   => 'app.realpush.cc',
                                   :port   => 443,
                                   :path   => "/api/#{RealPush::API_VERSION_BE}#{path}"
                               })
          end

          # Validate a params accepted
          #
          # @param params [Hash]
          #
          # @return [TrueClass]
          def valid_params?(params)
            params.keys.each do |key|
              unless RealPush::API::App.params_accept.include? key.to_sym
                raise ConfigurationError, "Invalid parameter! ( #{RealPush::API::App.params_accept.join(', ')} )"
              end
            end
            true
          end

        end
      end

      module ClassMethods
        attr_reader :params_accept, :params

        def accept_params(*args)
          @params_accept ||= []
          args.each do |field|
            @params_accept << field
          end
        end

        def configure(params={})
          @params = {
              base_path: nil,
              modules: [
                  :list,
                  :create,
                  :update,
                  :destroy
              ]
          }.deep_merge(params.symbolize_keys)
          raise ConfigurationError, 'Invalid parameters, you need a "base_path"' unless params[:base_path]
          @params[:modules].each do |a|
            a = a.to_s.downcase
            send(:include, Object.const_get("RealPush::API::Base#{a[0].upcase}#{a[1..-1]}"))
          end
        end


      end
    end

  end
end