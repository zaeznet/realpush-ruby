module RealPush
  module API
    module BaseList
      extend ActiveSupport::Concern

      def self.included(base)
        base.class_eval do
          def list
            content = execute :get, url("#{self.class.params[:base_path]}.json")
            parse_content content
          rescue RealPush::HTTPError => e
            {
                status: :ERROR,
                message: e.message
            }
          end
        end
      end
      
    end
  end
end