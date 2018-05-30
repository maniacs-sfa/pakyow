# frozen_string_literal: true

require "pakyow/support/makeable"
require "pakyow/support/class_state"

require "pakyow/data/command"
require "pakyow/data/sources/abstract"

module Pakyow
  module Data
    # Represents a data source through which you interact with a persistence
    # layer such as a sql database, redis, or http. Defines the schema, queries,
    # and other adapter-specific metadata (e.g. sql table). All data access
    # occurs through queries. Mutations occur through commands.
    #
    # Each adapter provides its own interface for interacting with the underlying
    # persistence layer. For example, the sql adapter exposes +Sequel::Dataset+
    # provided by the *fantastic* Sequel gem.
    #
    # Commands blindly accept input and do not implement validation, though input
    # will be coerced to the appropriate type. Use the input verifier pattern to
    # verify and validate input before passing it to a data source
    # (@see Pakyow::Verifier).
    #
    # Queries always return a {Pakyow::Data::Proxy} object containing the value
    # returned as well as metadata describing the query. Access to the
    # underlying value is provided through methods such as +one+, +to_a+, and
    # +each+ (@see Pakyow::Data::Proxy).
    #
    # Sources accept an optional +object_map+ for mapping values to instances of
    # +Pakyow::Data::Object+. If an object matching the source name is found,
    # instances of that object will be returned as results.
    #
    # @example
    #   source :posts, adapter: :sql, connection: :default do
    #     table :posts
    #
    #     primary_id
    #     timestamps
    #
    #     attribute :title, :string
    #
    #     command :create do |params|
    #       insert(params)
    #     end
    #
    #     def by_id(id)
    #       where(id: id)
    #     end
    #   end
    #
    #   data.posts.by_id(1).first
    #
    class Source < Sources::Abstract
      # @api private
      attr_reader :container, :included

      def initialize(dataset, container:, object_map: {})
        __setobj__(dataset)
        @container, @object_map = container, object_map
        @wrap_as = self.class.singular_name
        @included = []

        if default_query = self.class.__default_query
          result = if default_query.is_a?(Proc)
            instance_exec(&default_query)
          else
            public_send(self.class.__default_query)
          end

          __setobj__(result.__getobj__)
        end
      end

      def all
        self
      end

      def including(source_name, &block)
        included_source = @container.source_instance(source_name)

        if included_association = self.class.find_association_to_source(included_source)
          source_from_self(__getobj__).tap { |returned_source|
            if included_association[:query_name]
              included_source = included_source.send(included_association[:query_name])
            end

            final_source = if block_given?
              included_source.instance_exec(&block) || included_source
            else
              included_source
            end

            returned_source.instance_variable_get(:@included) << final_source
          }
        else
          # TODO: raise a nicer error indicating what associations are available
          raise "unknown association for #{source_name}"
        end
      end

      def as(object)
        @wrap_as = object
        self
      end

      def each(&block)
        to_a.each(&block)
      end

      def map(&block)
        to_a.map(&block)
      end

      def to_a
        return @results if instance_variable_defined?(:@results)
        @results = self.class.to_a(__getobj__)
        include_results!(@results)
        @results.map! { |result|
          wrap(result)
        }
      end

      def one
        return @results.first if instance_variable_defined?(:@results)
        return @result if instance_variable_defined?(:@result)

        if result = self.class.one(__getobj__)
          include_results!([result])
          @result = result
          wrap(@result)
        else
          nil
        end
      end

      def transaction(&block)
        @container.connection.transaction(&block)
      end

      def command(command_name)
        if command = self.class.commands[command_name]
          Command.new(
            command_name,
            block: command[:block],
            source: self,
            provides_dataset: command[:provides_dataset],
            performs_update: command[:performs_update]
          )
        else
          # TODO: raise a nicer error indicating what commands are available
          raise "unknown command #{command_name}"
        end
      end

      def source_name
        self.class.__class_name.name
      end

      def command?(maybe_command_name)
        self.class.commands.include?(maybe_command_name)
      end

      def query?(maybe_query_name)
        self.class.queries.include?(maybe_query_name)
      end

      RESULT_METHODS = %i(each to_a one count transaction to_json).freeze
      def result?(maybe_result_name)
        RESULT_METHODS.include?(maybe_result_name)
      end

      MODIFIER_METHODS = %i(all as including).freeze
      def modifier?(maybe_modifier_name)
        MODIFIER_METHODS.include?(maybe_modifier_name)
      end

      NESTED_METHODS = %i(including).freeze
      def block_for_nested_source?(maybe_nested_name)
        NESTED_METHODS.include?(maybe_nested_name)
      end

      def to_json(*)
        to_a.to_json
      end

      private

      def source_from_self(dataset)
        Source.source_from_source(self, dataset)
      end

      def wrap(result)
        @object_map.fetch(@wrap_as, Object).new(result)
      end

      def include_results!(results)
        @included.each do |combined_source|
          association = self.class.find_association_to_source(combined_source)

          combined_source.__setobj__(
            combined_source.container.connection.adapter.result_for_attribute_value(
              association[:associated_column_name] || combined_source.class.primary_key_field,
              results.map { |result| result[association[:column_name]] },
              combined_source
            )
          )

          combined_results = combined_source.to_a.group_by { |combined_result|
            combined_result[association[:associated_column_name] || combined_source.class.primary_key_field]
          }

          if association[:type] == :has_many
            result_key = combined_source.class.plural_name
            result_type = :many
          else
            result_key = combined_source.class.singular_name
            result_type = :one
          end

          results.map! { |result|
            combined_results_for_result = combined_results[result[association[:column_name]]].to_a
            result[result_key] = if result_type == :one
              combined_results_for_result[0]
            else
              combined_results_for_result
            end

            result
          }
        end
      end

      extend Support::Makeable
      extend Support::ClassState

      class_state :__default_query
      class_state :timestamp_fields
      class_state :primary_key_field
      class_state :attributes, default: {}
      class_state :qualifications, default: {}
      class_state :associations, default: { has_many: [], belongs_to: [] }
      class_state :commands, default: {}

      class << self
        attr_reader :name, :adapter, :connection

        def make(name, adapter: Pakyow.config.data.default_adapter, connection: Pakyow.config.data.default_connection, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, adapter: adapter, connection: connection, attributes: {}, **kwargs) do
            # Extend the source with any adapter-specific behavior.
            #
            include(Connection.adapter(adapter).const_get("SourceExtension"))

            # Call the original block.
            #
            class_eval(&block) if block_given?
          end
        end

        def source_from_source(source, dataset)
          source.dup.tap do |duped_source|
            duped_source.__setobj__(dataset)
          end
        end

        def command(command_name, provides_dataset: true, performs_update: false, &block)
          @commands[command_name] = {
            block: block,
            provides_dataset: provides_dataset,
            performs_update: performs_update
          }
        end

        def queries
          instance_methods - superclass.instance_methods
        end

        def query(query_name = nil, &block)
          @__default_query = query_name || block
        end

        def timestamps(create: :created_at, update: :updated_at)
          @timestamp_fields = {
            create: create,
            update: update
          }

          attribute create, :datetime
          attribute update, :datetime
        end

        def primary_id
          primary_key :id
          attribute :id, :integer
        end

        def primary_key(field)
          @primary_key_field = field
        end

        def attribute(name, type = :string, **options)
          attributes[name.to_sym] = {
            type: type,
            options: options
          }
        end

        def subscribe(query_name, qualifications)
          @qualifications[query_name] = qualifications
        end

        def qualifications(query_name)
          @qualifications.dig(query_name) || {}
        end

        # rubocop:disable Naming/PredicateName
        def has_many(source_name, query: nil)
          plural_name = Support.inflector.pluralize(source_name)

          @associations[:has_many] << {
            type: :has_many,
            access_type: :many,
            access_name: plural_name.to_sym,
            source_name: plural_name.to_sym,
            query_name: query,
            column_name: primary_key_field,
            associated_column_name: :"#{singular_name}_id"
          }
        end
        # rubocop:enable Naming/PredicateName

        def belongs_to(source_name)
          plural_name = Support.inflector.pluralize(source_name)
          singular_name = Support.inflector.singularize(source_name)

          @associations[:belongs_to] << {
            type: :belongs_to,
            access_type: :one,
            access_name: singular_name.to_sym,
            source_name: plural_name.to_sym,
            column_name: :"#{singular_name}_id",
            column_type: :integer
          }
        end

        def plural_name
          Support.inflector.pluralize(__class_name.name).to_sym
        end

        def singular_name
          Support.inflector.singularize(__class_name.name).to_sym
        end

        def find_association_to_source(source)
          associations.values.flatten.find { |association|
            association[:source_name] == source.class.plural_name ||
              association[:source_name] == source.class.singular_name
          }
        end
      end
    end
  end
end

# module Pakyow
#   module Data
#     class Source < SimpleDelegator
#       attr_reader :model

#       def initialize(model:, relation:)
#         @model = model
#         __setobj__(relation)
#       end

#       def command?(maybe_command_name)
#         %i[create update delete].include?(maybe_command_name)
#       end

#       def create(values)
#         set_ids_for_belongs_to_associations!(values)
#         command(:create).call(values)
#       end

#       def update(values)
#         set_ids_for_belongs_to_associations!(values)
#         command(:update).call(values)
#       end

#       def delete
#         command(:delete).call
#       end

#       def all
#         if mappable?
#           map_with(:model).to_a
#         else
#           to_a
#         end
#       end

#       def one
#         if mappable?
#           map_with(:model).one
#         else
#           super
#         end
#       end

#       def each(&block)
#         map_with(:model).each(&block)
#       end

#       def empty?
#         count == 0
#       end

#       private

#       def set_ids_for_belongs_to_associations!(values)
#         @model.associations[:belongs_to].each do |association|
#           association = Support.inflector.singularize(association[:model]).to_sym
#           if values.key?(association)
#             values[:"#{association}_id"] = values[association][:id]
#           end
#         end
#       end

#       UNMAPPABLE = [
#         ROM::Relation::Composite
#       ].freeze

#       def mappable?
#         !UNMAPPABLE.include?(__getobj__.class)
#       end
#     end
#   end
# end