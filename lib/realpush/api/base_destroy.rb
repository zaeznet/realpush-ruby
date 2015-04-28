module RealPush
  module API
    module BaseDestroy
      extend ActiveSupport::Concern

      def self.included(base)
        base.class_eval do
          def destroy(id)
            content = execute :delete, url("#{self.class.params[:base_path]}/#{id}.json")
            content.status == 204
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