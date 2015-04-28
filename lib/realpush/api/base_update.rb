module RealPush
  module API
    module BaseUpdate
      extend ActiveSupport::Concern

      def self.included(base)
        base.class_eval do
          def update(id, data)
            valid_params? data
            content = execute :patch, url("#{self.class.params[:base_path]}/#{id}.json"), {}, data
            parse_content content
          rescue RealPush::HTTPError,
                 RealPush::ConfigurationError => e
            raise RealPush::ConfigurationError, e.message
          end
        end
      end

    end
  end
end