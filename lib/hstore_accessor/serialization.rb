module HstoreAccessor
  module Serialization
    InvalidDataTypeError = Class.new(StandardError)

    VALID_TYPES = [:string, :integer, :float, :datetime, :boolean, :array, :hash, :date, :decimal]

    DEFAULT_SERIALIZER = ->(value) { value.to_s }
    DEFAULT_DESERIALIZER = DEFAULT_SERIALIZER

    SERIALIZERS = {
      array: -> value { value && YAML.dump(Array.wrap(value)) },
      boolean: -> value { (value.to_s == "true").to_s },
      date: -> value { value && value.to_s },
      hash: lambda do |value|
        if value
          raise InvalidDataTypeError, "Cannot serialize a non-hash value into the hash typed attribute" unless value.is_a?(Hash)
          YAML.dump(value)
        end
      end,
      datetime: -> value { value && value.to_i }
    }
    SERIALIZERS.default = DEFAULT_SERIALIZER

    DESERIALIZERS = {
      array: -> value { value && YAML.load(value) },
      boolean: -> value { TypeHelpers.cast(:boolean, value) },
      date: -> value { value && Date.parse(value) },
      decimal: -> value { value && BigDecimal.new(value) },
      float: -> value { value && value.to_f },
      hash: -> value { value && YAML.load(value) },
      integer: -> value { value && value.to_i },
      datetime: -> value { value && Time.at(value.to_i) }
    }
    DESERIALIZERS.default = DEFAULT_DESERIALIZER

    OLD_SEPARATOR = "||;||"

    class << self
      def serialize(type, value, serializer=SERIALIZERS[type])
        return nil if value.nil?

        serializer.call(value)
      end

      def deserialize(type, value, deserializer=DESERIALIZERS[type])
        return nil if value.nil?

        deserializer.call(value)
      end

      def migrate_array(old_array)
        return if old_array.nil?
        SERIALIZERS[:array].call(old_array.split(OLD_SEPARATOR))
      end

      def migrate_hash(old_hash)
        return if old_hash.nil?
        SERIALIZERS[:hash].call(JSON.parse(old_hash))
      end
    end
  end
end
