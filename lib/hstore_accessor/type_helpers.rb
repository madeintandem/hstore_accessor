module HstoreAccessor
  module TypeHelpers
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
