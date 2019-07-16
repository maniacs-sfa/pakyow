# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Config
    module Realtime
      extend Support::Extension

      apply_extension do
        configurable :realtime do
          setting :server, true

          setting :adapter, :memory
          setting :adapter_settings, {}

          defaults :production do
            setting :adapter, :redis
            setting :adapter_settings do
              Pakyow.config.redis.to_h
            end
          end
        end
      end
    end
  end
end
