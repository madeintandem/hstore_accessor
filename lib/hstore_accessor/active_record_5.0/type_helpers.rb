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
      # Resolve the calling model's connection only for modern column metadata.
      def column_type_for(attribute, data_type)
        metadata = if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new("7.2")
                     ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
                       sql_type: yield.type_to_sql(data_type),
                       type: data_type
                     )
                   else
                     TYPES[data_type].new
                   end
        ActiveRecord::ConnectionAdapters::Column.new(attribute.to_s, nil, metadata)
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
