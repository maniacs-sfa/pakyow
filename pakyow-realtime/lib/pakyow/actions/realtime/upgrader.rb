# frozen_string_literal: true

require "pakyow/support/message_verifier"

require "pakyow/realtime/websocket"

module Pakyow
  module Actions
    module Realtime
      class Upgrader
        def call(connection)
          if websocket?(connection)
            WebSocket.new(connection.verifier.verify(connection.params[:id]), connection)
            connection.halt
          end
        rescue Support::MessageVerifier::TamperedMessage
          connection.status = 403
          connection.halt
        end

        private

        def websocket?(connection)
          connection.path == "/pw-socket"
        end
      end
    end
  end
end
