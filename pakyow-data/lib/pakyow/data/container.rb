# frozen_string_literal: true

module Pakyow
  module Data
    class Container
      attr_reader :connection, :sources

      def initialize(connection:, sources:, objects:)
        @connection, @sources = connection, sources

        @object_map = objects.each_with_object({}) { |object, map|
          map[object.__class_name.name] = object
        }

        finalize!
      end

      def source_instance(source_name)
        plural_source_name = Support.inflector.pluralize(source_name).to_sym

        if source = sources.find { |source|
             source.plural_name == plural_source_name
           }

          source.new(
            @connection.dataset_for_source(source),
            object_map: @object_map,
            container: self
          )
        else
          # TODO: raise UnknownSource
        end
      end

      private

      def adapter
        @connection.adapter
      end

      def finalize!
        @sources.each do |source|
          define_inverse_associations!(source)
        end

        @sources.each do |source|
          mixin_commands!(source)
          mixin_dataset_methods!(source)
          define_attributes_for_associations!(source)
          define_queries_for_attributes!(source)
          wrap_defined_queries!(source)
          finalize_source_types!(source)
        end
      end

      def mixin_commands!(source)
        source.include adapter.class.const_get("Commands")
      end

      def mixin_dataset_methods!(source)
        source.extend adapter.class.const_get("DatasetMethods")
      end

      def define_attributes_for_associations!(source)
        source.associations[:belongs_to].each do |belongs_to_association|
          source.attribute(
            belongs_to_association[:column_name],
            belongs_to_association[:column_type],
            foreign_key: belongs_to_association[:source_name]
          )
        end
      end

      def define_inverse_associations!(source)
        source.associations[:has_many].each do |has_many_association|
          if associated_source = @sources.find { |potentially_associated_source|
               potentially_associated_source.plural_name == has_many_association[:source_name]
             }

            associated_source.belongs_to(source.plural_name)
          end
        end
      end

      def define_queries_for_attributes!(source)
        source.attributes.keys.each do |attribute|
          source.class_eval do
            define_method :"by_#{attribute}" do |value|
              @container.connection.adapter.result_for_attribute_value(attribute, value, self)
            end

            # Qualify the query.
            #
            subscribe :"by_#{attribute}", attribute => :__arg0__
          end
        end
      end

      # Override queries with methods that wrap the dataset in a source.
      #
      def wrap_defined_queries!(source)
        local_queries = source.queries
        source.prepend(
          Module.new do
            local_queries.each do |query|
              define_method query do |*args, &block|
                source_from_self(super(*args, &block))
              end
            end
          end
        )
      end

      def finalize_source_types!(source)
        source.attributes.each do |attribute_name, attribute_info|
          type = Types.type_for(attribute_info[:type], connection.types)

          if attribute_name == source.primary_key_field
            type = type.meta(primary_key: true)
          end

          source.attributes[attribute_name] = type.meta(**attribute_info[:options])
        end
      end
    end
  end
end