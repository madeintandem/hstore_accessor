module HstoreAccessor
  module TypeHelpers
    if ::ActiveRecord::VERSION::STRING.to_f >= 4.2
      class << self
        def cast(type, value)
          return nil if value.nil?

          case type
          when :string, :hash, :array, :decimal
            value
          when :integer, :float, :time, :date, :boolean
            types[type].type_cast_from_user(value)
          else value
            # Nothing.
          end
        end

        def types
          {
            integer: ::ActiveRecord::Type::Integer.new,
            float: ::ActiveRecord::Type::Float.new,
            time: ::ActiveRecord::Type::DateTime.new,
            date: ::ActiveRecord::Type::Date.new,
            string: ::ActiveRecord::Type::String.new,
            boolean: ::ActiveRecord::Type::Boolean.new
          }
        end
      end
    else
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
        when :time
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
