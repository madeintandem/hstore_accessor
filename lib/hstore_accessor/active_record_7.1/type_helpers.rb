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
        cast_type = TYPES[data_type].new

        sql_type_metadata = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
          sql_type: cast_type.type.to_s,
          type: cast_type.type,
          limit: cast_type.limit,
          precision: cast_type.precision,
          scale: cast_type.scale)

        ActiveRecord::ConnectionAdapters::Column.new(attribute.to_s, sql_type_metadata)
      end

      def cast(type, value)
        return nil if value.nil?

        case type
        when :string, :decimal
          value
        when :integer, :float, :datetime, :date, :boolean
          TYPES[type].new.cast(value)
        else value
        # Nothing.
        end
      end
    end
  end
end
