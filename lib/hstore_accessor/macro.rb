module HstoreAccessor
  module Macro
    module ClassMethods
      def hstore_accessor(hstore_attribute, fields)
        @@hstore_keys_and_types ||= {}

        "hstore_metadata_for_#{hstore_attribute}".tap do |method_name|
          singleton_class.send(:define_method, method_name) do
            fields
          end

          delegate method_name, to: :class
        end

        field_methods = Module.new

        if ActiveRecord::VERSION::STRING.to_f >= 4.2
          singleton_class.send(:define_method, :type_for_attribute) do |attribute|
            data_type = @@hstore_keys_and_types[attribute]
            if data_type
              TypeHelpers::TYPES[data_type].new
            else
              super(attribute)
            end
          end

          singleton_class.send(:define_method, :column_for_attribute) do |attribute|
            data_type = @@hstore_keys_and_types[attribute.to_s]
            if data_type
              TypeHelpers.column_type_for(attribute.to_s, data_type)
            else
              super(attribute)
            end
          end
        else
          field_methods.send(:define_method, :column_for_attribute) do |attribute|
            data_type = @@hstore_keys_and_types[attribute.to_s]
            if data_type
              TypeHelpers.column_type_for(attribute.to_s, data_type)
            else
              super(attribute)
            end
          end
        end

        fields.each do |key, type|
          data_type = type
          store_key = key

          if type.is_a?(Hash)
            type = type.with_indifferent_access
            data_type = type[:data_type]
            store_key = type[:store_key]
          end

          data_type = data_type.to_sym

          raise Serialization::InvalidDataTypeError unless Serialization::VALID_TYPES.include?(data_type)

          @@hstore_keys_and_types[key.to_s] = data_type

          field_methods.instance_eval do
            define_method("#{key}=") do |value|
              casted_value = TypeHelpers.cast(data_type, value)
              serialized_value = Serialization.serialize(data_type, casted_value)

              unless send(key) == casted_value
                send("#{hstore_attribute}_will_change!")
              end

              send("#{hstore_attribute}=", (send(hstore_attribute) || {}).merge(store_key.to_s => serialized_value))
            end

            define_method(key) do
              value = send(hstore_attribute) && send(hstore_attribute).with_indifferent_access[store_key.to_s]
              Serialization.deserialize(data_type, value)
            end

            define_method("#{key}?") do
              send(key).present?
            end

            define_method("#{key}_changed?") do
              send("#{key}_change").present?
            end

            define_method("saved_change_to_#{key}") do
              hstore_changes = previous_changes[hstore_attribute]
              return if hstore_changes.nil?
              attribute_changes = hstore_changes.map { |change| change.try(:[], store_key.to_s) }
              attribute_changes.uniq.size == 1 ? nil : attribute_changes
            end

            define_method("saved_change_to_#{key}?") do
              send("saved_change_to_#{key}").present?
            end

            define_method("#{key}_was") do
              (send(:attribute_was, hstore_attribute.to_s) || {})[key.to_s]
            end

            define_method("#{key}_change") do
              hstore_changes = send("#{hstore_attribute}_change")
              return if hstore_changes.nil?
              attribute_changes = hstore_changes.map { |change| change.try(:[], store_key.to_s) }
              attribute_changes.uniq.size == 1 ? nil : attribute_changes
            end

            define_method("restore_#{key}!") do
              old_hstore = send("#{hstore_attribute}_change").try(:first) || {}
              send("#{key}=", old_hstore[key.to_s])
            end

            define_method("reset_#{key}!") do
              if ActiveRecord::VERSION::STRING.to_f >= 4.2
                ActiveSupport::Deprecation.warn(<<-MSG.squish)
                  `#reset_#{key}!` is deprecated and will be removed on Rails 5.
                  Please use `#restore_#{key}!` instead.
                MSG
              end
              send("restore_#{key}!")
            end

            define_method("#{key}_will_change!") do
              send("#{hstore_attribute}_will_change!")
            end
          end

          query_field = "#{table_name}.#{hstore_attribute} -> '#{store_key}'"
          eq_query_field = "#{table_name}.#{hstore_attribute} @> hstore('#{store_key}', ?)"

          case data_type
          when :string
            send(:scope, "with_#{key}", -> value { where(eq_query_field, value.to_s) })
          when :integer
            send(:scope, "#{key}_lt", -> value { where("(#{query_field})::#{data_type} < ?", value.to_s) })
            send(:scope, "#{key}_lte", -> value { where("(#{query_field})::#{data_type} <= ?", value.to_s) })
            send(:scope, "#{key}_eq", -> value { where(eq_query_field, value.to_s) })
            send(:scope, "#{key}_gte", -> value { where("(#{query_field})::#{data_type} >= ?", value.to_s) })
            send(:scope, "#{key}_gt", -> value { where("(#{query_field})::#{data_type} > ?", value.to_s) })
          when :float, :decimal
            send(:scope, "#{key}_lt", -> value { where("(#{query_field})::#{data_type} < ?", value.to_s) })
            send(:scope, "#{key}_lte", -> value { where("(#{query_field})::#{data_type} <= ?", value.to_s) })
            send(:scope, "#{key}_eq", -> value { where("(#{query_field})::#{data_type} = ?", value.to_s) })
            send(:scope, "#{key}_gte", -> value { where("(#{query_field})::#{data_type} >= ?", value.to_s) })
            send(:scope, "#{key}_gt", -> value { where("(#{query_field})::#{data_type} > ?", value.to_s) })
          when :datetime
            send(:scope, "#{key}_before", -> value { where("(#{query_field})::integer < ?", value.to_i) })
            send(:scope, "#{key}_eq", -> value { where(eq_query_field, value.to_i.to_s) })
            send(:scope, "#{key}_after", -> value { where("(#{query_field})::integer > ?", value.to_i) })
          when :date
            send(:scope, "#{key}_before", -> value { where("#{query_field} < ?", value.to_s) })
            send(:scope, "#{key}_eq", -> value { where(eq_query_field, value.to_s) })
            send(:scope, "#{key}_after", -> value { where("#{query_field} > ?", value.to_s) })
          when :boolean
            send(:scope, "is_#{key}", -> { where(eq_query_field, "true") })
            send(:scope, "not_#{key}", -> { where(eq_query_field, "false") })
          end
        end

        include field_methods
      end
    end
  end
end
