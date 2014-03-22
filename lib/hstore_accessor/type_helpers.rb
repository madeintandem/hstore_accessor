module HstoreAccessor
  module TypeHelpers

    def self.cast(type, value)
      return nil if value.nil?
      column_class = ActiveRecord::ConnectionAdapters::Column
      case type
      when :string,:hash,:array,
        :decimal                 then value
      when :integer              then column_class.value_to_integer(value)
      when :float                then value.to_f
      when :time                 then TimeHelper.string_to_time(value)
      when :date                 then column_class.value_to_date(value)
      when :boolean              then column_class.value_to_boolean(value)
      else value
      end
    end

  end
end
