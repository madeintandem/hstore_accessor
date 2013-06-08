require "hstore_accessor/version"
require "active_support"
require "active_record"

module HstoreAccessor

  InvalidDataTypeError = Class.new(StandardError)

  VALID_TYPES = [:string, :integer, :float, :array, :hash]

  DEFAULT_SERIALIZER = ->(val) { val.to_s }
  DEFAULT_DESERIALIZER = ->(val) { val.to_s }

  SERIALIZERS = {
    :array => ->(val) { val.to_json },
    :hash => ->(val) { val.to_json }
  }

  DESERIALIZERS = {
    :array => ->(val) { JSON.parse(val) },
    :hash => ->(val) { JSON.parse(val) },
    :integer => ->(val) { val.to_i },
    :float => ->(val) { val.to_f }
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

        #send(:scope, "for_#{key}", -> value { where("#{hstore_attribute} -> '#{key}'=?", value.to_s)})
      end

    end

  end

end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, HstoreAccessor)
end
