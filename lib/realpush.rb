autoload 'Logger', 'logger'
require 'active_support/all'

module RealPush
  # All errors descend from this class so they can be easily rescued
  #
  # @example
  #   begin
  #     RealPush.trigger('channel_name', 'event_name, {:some => 'data'})
  #   rescue RealPush::Error => e
  #     # Do something on error
  #   end
  class Error < RuntimeError; end
  class AuthenticationError < Error; end
  class ConfigurationError < Error; end
  class HTTPError < Error; end

  API_VERSION_BE  = 'v1'
  API_VERSION_APP = 'v1'

  autoload :Client,   'realpush/client'
  autoload :Request,  'realpush/request'
  autoload :Resource, 'realpush/resource'

  class << self
    attr_writer :logger

    def logger
      @logger ||= begin
        log = Logger.new($stdout)
        log.level = Logger::INFO
        log
      end
    end

    def default_client
      @default_client ||= Client.new
    end

    %w(trigger trigger_async post post_async get get_async).each do |method|
      delegate method, to: 'default_client'
    end
  end

  module API
    autoload :App,         'realpush/api/app'
    autoload :Base,        'realpush/api/base'
    autoload :BaseCreate,  'realpush/api/base_create'
    autoload :BaseDestroy, 'realpush/api/base_destroy'
    autoload :BaseList,    'realpush/api/base_list'
    autoload :BaseUpdate,  'realpush/api/base_update'
  end
end

require 'realpush/version'
