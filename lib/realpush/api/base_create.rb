module RealPush
  module API
    module BaseCreate
      extend ActiveSupport::Concern

      def self.included(base)
        base.class_eval do
          def create(data)
            valid_params? data
            content = execute :post, url("#{self.class.params[:base_path]}.json"), {}, data
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