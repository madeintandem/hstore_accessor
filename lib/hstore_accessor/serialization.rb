module HstoreAccessor
  module Serialization
    InvalidDataTypeError = Class.new(StandardError)

    VALID_TYPES = [:string, :integer, :float, :time, :boolean, :array, :hash, :date, :decimal]

    DEFAULT_SERIALIZER = ->(value) { value.to_s }
    DEFAULT_DESERIALIZER = DEFAULT_SERIALIZER

    SERIALIZERS = {
      array: -> value { (value && YAML.dump(Array.wrap(value))) || nil },
      boolean: -> value { (value.to_s == "true").to_s },
      date: -> value { (value && value.to_s) || nil },
      hash: lambda do |value|
        if value
          raise InvalidDataTypeError, "Cannot serialize a non-hash value into the hash typed attribute" unless value.is_a?(Hash)
          YAML.dump(value)
        else
          nil
        end
      end,
      time: -> value { (value && value.to_i) || nil }
    }

    DESERIALIZERS = {
      array: -> value { (value && YAML.load(value)) || nil },
      boolean: -> value { TypeHelpers.cast(:boolean, value) },
      date: -> value { (value && Date.parse(value)) || nil },
      decimal: -> value { (value && BigDecimal.new(value)) || nil },
      float: -> value { (value && value.to_f) || nil },
      hash: -> value { (value && YAML.load(value)) || nil },
      integer: -> value { (value && value.to_i) || nil },
      time: -> value { (value && Time.at(value.to_i)) || nil }
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
  end
end
