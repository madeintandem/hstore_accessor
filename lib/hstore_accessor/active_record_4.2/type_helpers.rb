module HstoreAccessor
  module TypeHelpers
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
        ActiveRecord::ConnectionAdapters::Column.new(attribute.to_s, nil, TYPES[data_type].new)
      end

      def cast(type, value)
        return nil if value.nil?

        case type
        when :string, :hash, :array, :decimal
          value
        when :integer, :float, :datetime, :date, :boolean
          TYPES[type].new.type_cast_from_user(value)
        else value
          # Nothing.
        end
      end
    end
  end
end
