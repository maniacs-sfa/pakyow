# frozen_string_literal: true

require "json"
require "securerandom"

require "pakyow/helpers/app"
require "pakyow/helpers/connection"

require "async/websocket"

require "protocol/websocket/connection"
require "protocol/websocket/headers"

module Pakyow
  module Realtime
    class WebSocket
      Frame = ::Protocol::WebSocket::Frame

      class Connection < ::Protocol::WebSocket::Connection
        include ::Protocol::WebSocket::Headers

        def self.call(framer, protocol = [], **options)
          return self.new(framer, Array(protocol).first, **options)
        end

        def initialize(framer, protocol = nil, **options)
          super(framer, **options)
          @protocol = protocol
        end

        attr :protocol

        def call
          self.close
        end
      end

      include Pakyow::Helpers::App
      include Pakyow::Helpers::Connection

      attr_reader :id

      def initialize(id, connection)
        @id, @connection, @open = id, connection, false
        @logger = Logger.new(:sock, id: @id[0..7], output: Pakyow.global_logger, level: Pakyow.config.logger.level)
        @server = @connection.app.websocket_server

        response = Async::WebSocket::Adapters::Native.open(@connection.request, handler: Connection) do |socket|
          @socket = socket

          handle_open
          while message = socket.read
            handle_message(message)
          end
        rescue EOFError, Protocol::WebSocket::ClosedError
        ensure
          @socket&.close; shutdown
        end

        @connection.__getobj__.instance_variable_set(:@response, response)
      end

      def open?
        @open == true
      end

      def transmit(message, raw: false)
        if open?
          if raw
            @socket.write(message)
          else
            @socket.write(JSON.dump(payload: message))
          end

          @socket.flush
        end
      end

      def beat
        transmit("beat")
      end

      # @api private
      def leave
        trigger_presence(:leave)
      end

      private

      def shutdown
        if open?
          @server.socket_disconnect(self)
          @open = false
          @logger.info "shutdown"
        end
      end

      def handle_open
        @server.socket_connect(self)
        @open = true
        trigger_presence(:join)
        @logger.info "opened"
        transmit_system_info
      end

      def handle_message(message)
        @logger.internal("< " + message)
      end

      def trigger_presence(event)
        @connection.app.hooks(:before, event).each do |hook, _|
          instance_exec(&hook[:block])
        end
      end

      def transmit_system_info
        transmit(
          channel: "system",
          message: {
            version: @connection.app.config.version
          }
        )
      end
    end
  end
end

module Async
  module WebSocket
    module Adapters
      module Native
        include ::Protocol::WebSocket::Headers

        def self.websocket?(request)
          request.headers.include?("upgrade")
        end

        def self.open(request, headers: [], protocols: [], handler: Connection, **options)
          if websocket?(request) && Array(request.protocol).include?(PROTOCOL)
            # Select websocket sub-protocol:
            if requested_protocol = request.headers[SEC_WEBSOCKET_PROTOCOL]
              protocol = (requested_protocol & protocols).first
            end

            Response.for(request, headers, protocol: protocol, **options) do |stream|
              framer = Protocol::WebSocket::Framer.new(stream)

              yield handler.call(framer, protocol)
            end
          else
            nil
          end
        end
      end
    end
  end
end
