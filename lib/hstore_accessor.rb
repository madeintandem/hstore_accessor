require "hstore_accessor/version"

module HstoreAccessor

  InvalidDataTypeError = Class.new(StandardError)

  VALID_TYPES = [:string, :integer, :float, :array, :hash]

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

  def serialize(type, value)
    serialized_value = value.to_s
    serialized_value = SERIALIZERS[type].call(value) if SERIALIZERS.has_key? type
    serialized_value
  end

  def deserialize(type, value)
    deserialized_value = value
    deserialized_value = DESERIALIZERS[type].call(value) if DESERIALIZERS.has_key? type
    deserialized_value
  end

  module ClassMethods

    def hstore_accessor(hstore_attribute, fields)

      fields.each do |key, type|

        raise InvalidDataTypeError unless VALID_TYPES.include?(type)

        define_method("#{key}=") do |value|
          send :"#{hstore_attribute}=", (send(hstore_attribute) || {}).merge(key.to_s => serialize(type, value))
          send :"#{hstore_attribute}_will_change!"
        end

        define_method(key) do
          value = send(hstore_attribute) && send(hstore_attribute)[key.to_s]
          deserialize(type, value)
        end

        send(:scope, "for_#{key}", -> value { where("#{hstore_attribute} -> '#{key}'=?", value.to_s)})
      end

    end

  end

end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, HstoreAccessor)
end
