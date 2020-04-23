# frozen_string_literal: true

command :boot, boot: false do
  describe "Boot the project"

  option :host, "The host the server runs on", default: -> { Pakyow.config.server.host }
  option :port, "The port the server runs on", default: -> { Pakyow.config.server.port }

  flag :standalone, "Disable automatic reloading of changes"

  action do
    Pakyow.config.server.host = @host
    Pakyow.config.server.port = @port
    Pakyow.run(env: @env)
  end
end
