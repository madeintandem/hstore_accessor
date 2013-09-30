require "hstore_accessor/version"
require "active_support"
require "active_record"

module HstoreAccessor
  extend ActiveSupport::Concern

  InvalidDataTypeError = Class.new(StandardError)

  VALID_TYPES = [:string, :integer, :float, :time, :boolean, :array, :hash, :date]

  SEPARATOR = "||;||"

  DEFAULT_SERIALIZER = ->(value) { value.to_s }
  DEFAULT_DESERIALIZER = DEFAULT_SERIALIZER

  SERIALIZERS = {
    :array    => -> value { (value && value.join(SEPARATOR)) || nil },
    :hash     => -> value { (value && value.to_json) || nil },
    :time     => -> value { value.to_i },
    :boolean  => -> value { (value == true).to_s },
    :date     => -> value { (value && value.to_s) || nil }
  }

  DESERIALIZERS = {
    :array    => -> value { (value && value.split(SEPARATOR)) || nil },
    :hash     => -> value { (value && JSON.parse(value)) || nil },
    :integer  => -> value { value.to_i },
    :float    => -> value { value.to_f },
    :time     => -> value { Time.at(value.to_i) },
    :boolean  => -> value { value == "true" },
    :date     => -> value { (value && Date.parse(value)) || nil }
  }

  def serialize(type, value, serializer=nil)
    return nil if value.nil?
    serializer ||= (SERIALIZERS[type] || DEFAULT_SERIALIZER)
    serializer.call(value)
  end

  def deserialize(type, value, deserializer=nil)
    return nil if value.nil?
    deserializer ||= (DESERIALIZERS[type] || DEFAULT_DESERIALIZER)
    deserializer.call(value)
  end

  module ClassMethods

    def hstore_accessor(hstore_attribute, fields)
      fields.each do |key, type|

        data_type = type
        store_key = key
        if type.is_a?(Hash)
          type = type.with_indifferent_access
          data_type = type[:data_type]
          store_key = type[:store_key]
        end

        raise InvalidDataTypeError unless VALID_TYPES.include?(data_type)

        define_method("#{key}=") do |value|
          send("#{hstore_attribute}=", (send(hstore_attribute) || {}).merge(store_key.to_s => serialize(data_type, value)))
          send("#{hstore_attribute}_will_change!")
        end

        define_method(key) do
          value = send(hstore_attribute) && send(hstore_attribute).with_indifferent_access[store_key.to_s]
          deserialize(data_type, value)
        end

        query_field = "#{hstore_attribute} -> '#{store_key}'"

        case data_type
        when :string
          send(:scope, "with_#{key}", -> value { where("#{query_field} = ?", value.to_s) })
        when :integer, :float
          send(:scope, "#{key}_lt",  -> value { where("(#{query_field})::#{data_type} < ?", value.to_s) })
          send(:scope, "#{key}_lte", -> value { where("(#{query_field})::#{data_type} <= ?", value.to_s) })
          send(:scope, "#{key}_eq",  -> value { where("(#{query_field})::#{data_type} = ?", value.to_s) })
          send(:scope, "#{key}_gte", -> value { where("(#{query_field})::#{data_type} >= ?", value.to_s) })
          send(:scope, "#{key}_gt",  -> value { where("(#{query_field})::#{data_type} > ?", value.to_s) })
        when :time
          send(:scope, "#{key}_before", -> value { where("(#{query_field})::integer < ?", value.to_i) })
          send(:scope, "#{key}_eq",     -> value { where("(#{query_field})::integer = ?", value.to_i) })
          send(:scope, "#{key}_after",  -> value { where("(#{query_field})::integer > ?", value.to_i) })
        when :date
          send(:scope, "#{key}_before", -> value { where("#{query_field} < ?", value.to_s) })
          send(:scope, "#{key}_eq",     -> value { where("#{query_field} = ?", value.to_s) })
          send(:scope, "#{key}_after",  -> value { where("#{query_field} > ?", value.to_s) })
        when :boolean
          send(:scope, "is_#{key}", -> { where("#{query_field} = 'true'") })
          send(:scope, "not_#{key}", -> { where("#{query_field} = 'false'") })
        when :array
          send(:scope, "#{key}_eq",        -> value { where("#{query_field} = ?", value.join(SEPARATOR)) })
          send(:scope, "#{key}_contains",  -> value do
            where("string_to_array(#{query_field}, '#{SEPARATOR}') @> string_to_array(?, '#{SEPARATOR}')", Array[value].flatten)
          end)
        end
      end

    end

  end

end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, HstoreAccessor)
end
