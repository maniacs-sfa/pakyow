# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/core/framework"

require "pakyow/data/types"
require "pakyow/data/lookup"
require "pakyow/data/entity"
require "pakyow/data/source"
require "pakyow/data/proxy"
require "pakyow/data/subscribers"
require "pakyow/data/errors"
require "pakyow/data/connection"
require "pakyow/data/container"
require "pakyow/data/auto_migrator"

module Pakyow
  module Data
    SUPPORTED_CONNECTION_TYPES = %i(sql)

    class Framework < Pakyow::Framework(:data)
      def boot
        if controller = app.const_get(:Controller)
          controller.class_eval do
            def data
              app.data
            end
          end
        end

        app.class_eval do
          stateful :source, Source
          stateful :entity, Entity

          # Autoload sources from the `sources` directory.
          #
          aspect :sources

          # Autoload entities from the `entities` directory.
          #
          aspect :entities

          # Data container object.
          #
          attr_reader :data

          after :initialize do
            # TODO: hook this back up later (probably in Container)
            # define_inverse_associations!

            @data = Lookup.new(
              containers: Pakyow.data_connections.values.each_with_object([]) { |connections, containers|
                connections.values.each do |connection|
                  containers << Container.new(
                    connection: connection,
                    sources: state_for(:source).select { |source|
                      connection.name == source.connection && connection.type == source.adapter
                    }
                  )
                end
              },
              subscribers: Subscribers.new(
                self,
                Pakyow.config.data.subscriptions.adapter,
                Pakyow.config.data.subscriptions.adapter_options
              )
            )
          end

          private

          # Defines inverse associations. For example, this method would define
          # a +belongs_to :post+ relationship on the +:comment+ model, when the
          # +:post+ model +has_many :comments+.
          #
          # def define_inverse_associations!
          #   state_for(:model).each do |model|
          #     model.associations[:has_many].each do |has_many_association|
          #       if associated_model = state_for(:model).flatten.find { |potentially_associated_model|
          #            potentially_associated_model.plural_name == has_many_association[:model]
          #          }

          #         associated_model.belongs_to(model.plural_name)
          #       end
          #     end
          #   end
          # end
        end
      end
    end

    Pakyow.module_eval do
      class << self
        # @api private
        attr_reader :data_connections

        # @api private
        # def relation(name, adapter, connection)
        #   unless relation = container(adapter, connection).relations[name]
        #     raise ArgumentError, "Unknown database relation `#{name}' for adapter `#{adapter}', connection `#{connection}'"
        #   end

        #   relation
        # end

        # @api private
        # def container(adapter, connection)
        #   adapter ||= Pakyow.config.data.default_adapter
        #   unless container = Pakyow.data_connections.dig(adapter, connection)
        #     raise ArgumentError, "Unknown database container container for adapter `#{adapter}', connection `#{connection}'"
        #   end

        #   container
        # end
      end

      settings_for :data do
        setting :default_adapter, :sql
        setting :default_connection, :default

        setting :logging, false
        setting :auto_migrate, true

        defaults :production do
          setting :auto_migrate, false
        end

        settings_for :subscriptions do
          setting :adapter, :memory
          setting :adapter_options, {}

          defaults :production do
            setting :adapter, :redis
            setting :adapter_options, redis_url: ENV["REDIS_URL"] || "redis://127.0.0.1:6379", redis_prefix: "pw"
          end
        end

        settings_for :connections do
          SUPPORTED_CONNECTION_TYPES.each do |type|
            setting type, {}
          end
        end
      end

      after :setup do
        @data_connections = SUPPORTED_CONNECTION_TYPES.each_with_object({}) { |connection_type, connections|
          connections[connection_type] = Pakyow.config.data.connections.public_send(connection_type).each_with_object({}) { |(connection_name, connection_string), adapter_connections|
            adapter_connections[connection_name] = Connection.new(
              connection_string,
              type: connection_type,
              name: connection_name
            )
          }
        }
      end

      after :boot do
        # TODO: reconsider doing this here
        # we could make it so that auto migrating is non-destructive... it'll
        # never remove tables / columns so that it's safe to do across apps

        if Pakyow.config.data.auto_migrate
          @data_connections.values.flat_map(&:values).select(&:auto_migrate?).each do |auto_migratable_connection|
            Pakyow::Data::AutoMigrator.new(
              connection: auto_migratable_connection,
              sources: apps.flat_map { |app| app.state_for(:source) }.select { |source|
                auto_migratable_connection.name == source.connection && auto_migratable_connection.type == source.adapter
              }
            ).migrate!
          end
        end
      end
    end
  end
end
