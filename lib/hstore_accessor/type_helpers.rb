module HstoreAccessor
  module TypeHelpers
    def self.cast(type, value)
      return nil if value.nil?

      case type
      when :string, :hash, :array, :decimal
        value
      when :integer
        ActiveRecord::Type::Integer.new.type_cast_from_user(value)
      when :float
        ActiveRecord::Type::Float.new.type_cast_from_user(value)
      when :time
        ActiveRecord::Type::DateTime.new.type_cast_from_user(value)
      when :date
        ActiveRecord::Type::Date.new.type_cast_from_user(value)
      when :boolean
        ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
      else value
        # Nothing.
      end
    end
  end
end
