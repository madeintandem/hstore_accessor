module HstoreAccessor
  module TypeHelpers
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
          boolean: ::ActiveRecord::Type::Boolean.new
        }
      end
    end
  end
end
