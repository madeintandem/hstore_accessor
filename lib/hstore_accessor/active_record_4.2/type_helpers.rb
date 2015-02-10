module HstoreAccessor
  module TypeHelpers
    TYPES = {
      boolean: ActiveRecord::Type::Boolean,
      date: ActiveRecord::Type::Date,
      datetime: ActiveRecord::Type::DateTime,
      decimal: ActiveRecord::Type::Decimal,
      float: ActiveRecord::Type::Float,
      integer: ActiveRecord::Type::Integer,
      string: ActiveRecord::Type::String
    }

    TYPES.default = ActiveRecord::Type::Value

    class << self
      def column_type_for(attribute, data_type)
        ActiveRecord::ConnectionAdapters::Column.new(attribute.to_s, nil, TYPES[data_type].new)
      end

      def cast(type, value)
        return nil if value.nil?

        case type
        when :string, :decimal
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
