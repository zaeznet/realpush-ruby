module RealPush
  module API
    class App
      include RealPush::API::Base

      configure base_path: 'apps'
      accept_params :alias_name, :max_connections, :max_daily_messages, :status

    end
  end
end
