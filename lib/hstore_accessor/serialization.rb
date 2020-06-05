module HstoreAccessor
  module Serialization
    InvalidDataTypeError = Class.new(StandardError)

    VALID_TYPES = [
      :boolean,
      :date,
      :datetime,
      :decimal,
      :float,
      :integer,
      :string
    ]

    DEFAULT_SERIALIZER = ->(value) { value.to_s }
    DEFAULT_DESERIALIZER = DEFAULT_SERIALIZER

    SERIALIZERS = {
      boolean: -> value { (value.to_s == "true").to_s },
      date: -> value { value && value.to_s },
      datetime: -> value { value && value.to_i }
    }
    SERIALIZERS.default = DEFAULT_SERIALIZER

    DESERIALIZERS = {
      boolean: -> value { TypeHelpers.cast(:boolean, value) },
      date: -> value { value && Date.parse(value) },
      decimal: -> value { value && (value == '' ? BigDecimal(0) : BigDecimal(value)) },
      float: -> value { value && value.to_f },
      integer: -> value { value && value.to_i },
      datetime: -> value { value && Time.at(value.to_i).in_time_zone }
    }
    DESERIALIZERS.default = DEFAULT_DESERIALIZER

    class << self
      def serialize(type, value, serializer=SERIALIZERS[type])
        return nil if value.nil?

        serializer.call(value)
      end

      def deserialize(type, value, deserializer=DESERIALIZERS[type])
        return nil if value.nil?

        deserializer.call(value)
      end
    end
  end
end
