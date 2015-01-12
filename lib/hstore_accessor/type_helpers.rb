module HstoreAccessor
  module TypeHelpers
    if ::ActiveRecord::VERSION::STRING.to_f >= 4.2
      TYPES = {
        string: ActiveRecord::Type::String,
        datetime: ActiveRecord::Type::DateTime,
        date: ActiveRecord::Type::Date,
        float: ActiveRecord::Type::Float,
        boolean: ActiveRecord::Type::Boolean,
        decimal: ActiveRecord::Type::Decimal,
        integer: ActiveRecord::Type::Integer,
        hash: ActiveRecord::Type::Value,
        array: ActiveRecord::Type::Value
      }

      class << self
        def column_type_for(attribute, data_type)
          ActiveRecord::ConnectionAdapters::Column.new(attribute.to_s, nil, types[data_type].new)
        end

        def cast(type, value)
          return nil if value.nil?

          case type
          when :string, :hash, :array, :decimal
            value
          when :integer, :float, :datetime, :date, :boolean
            types[type].new.type_cast_from_user(value)
          else value
            # Nothing.
          end
        end

        def types
          TYPES
        end
      end
    else
      TYPES = {
        string: "char",
        datetime: "datetime",
        date: "date",
        float: "float",
        boolean: "boolean",
        decimal: "decimal",
        integer: "int"
      }

      def self.column_type_for(attribute, data_type)
        ActiveRecord::ConnectionAdapters::Column.new(attribute.to_s, nil, TYPES[data_type])
      end

      def self.cast(type, value)
        return nil if value.nil?

        column_class = ActiveRecord::ConnectionAdapters::Column

        case type
        when :string, :hash, :array, :decimal
          value
        when :integer
          column_class.value_to_integer(value)
        when :float
          value.to_f
        when :datetime
          TimeHelper.string_to_time(value)
        when :date
          column_class.value_to_date(value)
        when :boolean
          column_class.value_to_boolean(value)
        else value
          # Nothing.
        end
      end
    end
  end
end
