module HstoreAccessor
  module TypeHelpers
    TYPES = {
      string: "char",
      datetime: "datetime",
      date: "date",
      float: "float",
      boolean: "boolean",
      decimal: "decimal",
      integer: "int"
    }

    class << self
      def column_type_for(attribute, data_type)
        ActiveRecord::ConnectionAdapters::Column.new(attribute.to_s, nil, TYPES[data_type])
      end

      def cast(type, value)
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
