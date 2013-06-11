require "hstore_accessor/version"
require "active_support"
require "active_record"

module HstoreAccessor

  InvalidDataTypeError = Class.new(StandardError)

  VALID_TYPES = [:string, :integer, :float, :time, :array, :hash]

  SEPARATOR = ";|;"

  DEFAULT_SERIALIZER = ->(value) { value.to_s }
  DEFAULT_DESERIALIZER = ->(value) { value.to_s }

  SERIALIZERS = {
    :array => ->(value) { value.join(SEPARATOR) },
    :hash => ->(value) { value.to_json },
    :time => ->(value) { value.to_i }
  }

  DESERIALIZERS = {
    :array => ->(value) { value.split(SEPARATOR) },
    :hash => ->(value) { JSON.parse(value) },
    :integer => ->(value) { value.to_i },
    :float => ->(value) { value.to_f },
    :time => ->(value) { Time.at(value.to_i) }
  }

  def self.included(base)
    base.extend(ClassMethods)
  end

  def serialize(type, value, serializer=nil)
    serializer ||= (SERIALIZERS[type] || DEFAULT_SERIALIZER)
    serializer.call(value)
  end

  def deserialize(type, value, deserializer=nil)
    deserializer ||= (DESERIALIZERS[type] || DEFAULT_DESERIALIZER)
    deserializer.call(value)
  end

  module ClassMethods

    def hstore_accessor(hstore_attribute, fields)

      fields.each do |key, type|

        raise InvalidDataTypeError unless VALID_TYPES.include?(type)

        define_method("#{key}=") do |value|
          send("#{hstore_attribute}=", (send(hstore_attribute) || {}).merge(key.to_s => serialize(type, value)))
          send("#{hstore_attribute}_will_change!")
        end

        define_method(key) do
          value = send(hstore_attribute) && send(hstore_attribute)[key.to_s]
          deserialize(type, value)
        end

        case type
        when :string
          send(:scope, "with_#{key}", -> value { where("#{hstore_attribute} -> '#{key}' = ?", value.to_s) })
        when :integer, :float
          send(:scope, "#{key}_lt",  -> value { where("#{hstore_attribute} -> '#{key}' < ?", value.to_s) })
          send(:scope, "#{key}_lte", -> value { where("#{hstore_attribute} -> '#{key}' <= ?", value.to_s) })
          send(:scope, "#{key}_eq",  -> value { where("#{hstore_attribute} -> '#{key}' = ?", value.to_s) })
          send(:scope, "#{key}_gte", -> value { where("#{hstore_attribute} -> '#{key}' >= ?", value.to_s) })
          send(:scope, "#{key}_gt",  -> value { where("#{hstore_attribute} -> '#{key}' > ?", value.to_s) })
        when :time
          send(:scope, "#{key}_before", -> value { where("to_number(#{hstore_attribute} -> '#{key}', '99999999999') < ?", value.to_i) })
          send(:scope, "#{key}_eq",     -> value { where("to_number(#{hstore_attribute} -> '#{key}', '99999999999') = ?", value.to_i) })
          send(:scope, "#{key}_after",  -> value { where("to_number(#{hstore_attribute} -> '#{key}', '99999999999') > ?", value.to_i) })
        when :array
          send(:scope, "#{key}_eq",        -> value { where("#{hstore_attribute} -> '#{key}' = ?", value.join(SEPARATOR)) })
          send(:scope, "#{key}_contains",  -> value do
            where("string_to_array(#{hstore_attribute} -> '#{key}', '#{SEPARATOR}') @> string_to_array(?, '#{SEPARATOR}')", Array[value].flatten)
          end)
        end
      end

    end

  end

end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, HstoreAccessor)
end
