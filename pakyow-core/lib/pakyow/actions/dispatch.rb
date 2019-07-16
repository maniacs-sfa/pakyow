# frozen_string_literal: true

module Pakyow
  module Actions
    class Dispatch
      def call(connection)
        catch :halt do
          Pakyow.apps.each do |app|
            if connection.path.start_with?(app.mount_path)
              app.call(connection)
            end
          end
        end

        unless connection.halted?
          error_404(connection)
        end
      rescue StandardError => error
        connection.error = error
        connection.logger.houston(error)
        error_500(connection)
      end

      private

      def error_404(connection, message = "404 Not Found")
        connection.status = 404
        connection.body = StringIO.new(message)
      end

      def error_500(connection, message = "500 Server Error")
        connection.status = 500
        connection.body = StringIO.new(message)
      end
    end
  end
end
