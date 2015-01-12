require "spec_helper"
require "active_support/all"

FIELDS = {
  color: :string,
  price: :integer,
  published: { data_type: :boolean, store_key: "p" },
  weight: { data_type: :float, store_key: "w" },
  popular: :boolean,
  build_timestamp: :datetime,
  tags: :array,
  reviews: :hash,
  released_at: :date,
  miles: :decimal
}

DATA_FIELDS = {
  color_data: :string
}

class Product < ActiveRecord::Base
  hstore_accessor :options, FIELDS
  hstore_accessor :data, DATA_FIELDS
end

describe HstoreAccessor do
  context "macro" do
    let(:product) { Product.new }

    FIELDS.keys.each do |field|
      it "creates a getter for the hstore field: #{field}" do
        expect(product).to respond_to(field)
      end

      it "creates a setter for the hstore field: #{field}=" do
        expect(product).to respond_to(:"#{field}=")
      end
    end

    it "raises an InvalidDataTypeError if an invalid type is specified" do
      expect do
        class FakeModel
          include HstoreAccessor
          hstore_accessor :foo, bar: :baz
        end
      end.to raise_error(HstoreAccessor::InvalidDataTypeError)
    end

    it "stores using the store_key if one is provided" do
      product.weight = 38.5
      product.save
      product.reload
      expect(product.options["w"]).to eq "38.5"
      expect(product.weight).to eq 38.5
    end
  end

  context "#hstore_metadata_for_*" do
    let(:product) { Product }

    it "returns the metadata hash for the specified field" do
      expect(product.hstore_metadata_for_options).to eq FIELDS
      expect(product.hstore_metadata_for_data).to eq DATA_FIELDS
    end

    context "instance method" do
      subject { Product.new }
      it { is_expected.to delegate_method(:hstore_metadata_for_options).to(:class) }
      it { is_expected.to delegate_method(:hstore_metadata_for_data).to(:class) }
    end
  end

  context "nil values" do
    let!(:timestamp) { Time.now }
    let!(:datestamp) { Date.today }
    let(:product) { Product.new }
    let(:persisted_product) { Product.create!(color: "green", price: 10, weight: 10.1, tags: %w(tag1 tag2 tag3), popular: true, build_timestamp: (timestamp - 10.days), released_at: (datestamp - 8.days), miles: BigDecimal.new("9.133790001")) }

    FIELDS.keys.each do |field|
      it "responds with nil when #{field} is not set" do
        expect(product.send(field)).to be_nil
      end

      it "responds with nil when #{field} is set back to nil after being set initially" do
        persisted_product.send("#{field}=", nil)
        expect(persisted_product.send(field)).to be_nil
      end
    end
  end

  describe "predicate methods" do
    let!(:product) { Product.new }

    it "exist for each field" do
      FIELDS.keys.each do |field|
        expect(product).to respond_to "#{field}?"
      end
    end

    it "uses 'present?' to determine return value" do
      stub = double(present?: :result_of_present)
      expect(stub).to receive(:present?)
      allow(product).to receive_messages(color: stub)
      expect(product.color?).to eq(:result_of_present)
    end

    context "boolean fields" do
      it "return the state for true boolean fields" do
        product.popular = true
        product.save
        product.reload
        expect(product.popular?).to be true
      end

      it "return the state for false boolean fields" do
        product.popular = false
        product.save
        product.reload
        expect(product.popular?).to be false
      end

      it "return true for boolean field set via hash using real boolean" do
        product.options = { "popular" => true }
        expect(product.popular?).to be true
      end

      it "return false for boolean field set via hash using real boolean" do
        product.options = { "popular" => false }
        expect(product.popular?).to be false
      end

      it "return true for boolean field set via hash using string" do
        product.options = { "popular" => "true" }
        expect(product.popular?).to be true
      end

      it "return false for boolean field set via hash using string" do
        product.options = { "popular" => "false" }
        expect(product.popular?).to be false
      end
    end
  end

  describe "scopes" do
    let!(:timestamp) { Time.now }
    let!(:datestamp) { Date.today }
    let!(:product_a) { Product.create(color: "green", price: 10, weight: 10.1, tags: %w(tag1 tag2 tag3), popular: true, build_timestamp: (timestamp - 10.days), released_at: (datestamp - 8.days), miles: BigDecimal.new("10.113379001")) }
    let!(:product_b) { Product.create(color: "orange", price: 20, weight: 20.2, tags: %w(tag2 tag3 tag4), popular: false, build_timestamp: (timestamp - 5.days), released_at: (datestamp - 4.days), miles: BigDecimal.new("20.213379001")) }
    let!(:product_c) { Product.create(color: "blue", price: 30, weight: 30.3, tags: %w(tag3 tag4 tag5), popular: true, build_timestamp: timestamp, released_at: datestamp, miles: BigDecimal.new("30.313379001")) }

    context "for string fields support" do
      it "equality" do
        expect(Product.with_color("orange").to_a).to eq [product_b]
      end
    end

    context "for integer fields support" do
      it "less than" do
        expect(Product.price_lt(20).to_a).to eq [product_a]
      end

      it "less than or equal" do
        expect(Product.price_lte(20).to_a).to eq [product_a, product_b]
      end

      it "equality" do
        expect(Product.price_eq(10).to_a).to eq [product_a]
      end

      it "greater than or equal" do
        expect(Product.price_gte(20).to_a).to eq [product_b, product_c]
      end

      it "greater than" do
        expect(Product.price_gt(20).to_a).to eq [product_c]
      end
    end

    context "for float fields support" do
      it "less than" do
        expect(Product.weight_lt(20.0).to_a).to eq [product_a]
      end

      it "less than or equal" do
        expect(Product.weight_lte(20.2).to_a).to eq [product_a, product_b]
      end

      it "equality" do
        expect(Product.weight_eq(10.1).to_a).to eq [product_a]
      end

      it "greater than or equal" do
        expect(Product.weight_gte(20.2).to_a).to eq [product_b, product_c]
      end

      it "greater than" do
        expect(Product.weight_gt(20.5).to_a).to eq [product_c]
      end
    end

    context "for decimal fields support" do
      it "less than" do
        expect(Product.miles_lt(BigDecimal.new("10.55555")).to_a).to eq [product_a]
      end

      it "less than or equal" do
        expect(Product.miles_lte(BigDecimal.new("20.213379001")).to_a).to eq [product_a, product_b]
      end

      it "equality" do
        expect(Product.miles_eq(BigDecimal.new("10.113379001")).to_a).to eq [product_a]
      end

      it "greater than or equal" do
        expect(Product.miles_gte(BigDecimal.new("20.213379001")).to_a).to eq [product_b, product_c]
      end

      it "greater than" do
        expect(Product.miles_gt(BigDecimal.new("20.555555")).to_a).to eq [product_c]
      end
    end

    context "for array fields support" do
      it "equality" do
        expect(Product.tags_eq(%w(tag1 tag2 tag3)).to_a).to eq [product_a]
      end
    end

    context "for time fields support" do
      it "before" do
        expect(Product.build_timestamp_before(timestamp)).to eq [product_a, product_b]
      end

      it "equality" do
        expect(Product.build_timestamp_eq(timestamp)).to eq [product_c]
      end

      it "after" do
        expect(Product.build_timestamp_after(timestamp - 6.days)).to eq [product_b, product_c]
      end
    end

    context "for date fields support" do
      it "before" do
        expect(Product.released_at_before(datestamp)).to eq [product_a, product_b]
      end

      it "equality" do
        expect(Product.released_at_eq(datestamp)).to eq [product_c]
      end

      it "after" do
        expect(Product.released_at_after(datestamp - 6.days)).to eq [product_b, product_c]
      end
    end

    context "for boolean field support" do
      it "true" do
        expect(Product.is_popular).to eq [product_a, product_c]
      end

      it "false" do
        expect(Product.not_popular).to eq [product_b]
      end
    end
  end

  describe "#type_for_attribute" do
    if ::ActiveRecord::VERSION::STRING.to_f >= 4.2
      subject { Product }

      def self.it_returns_the_type_for_the_attribute(type, attribute_name, active_record_type)
        context "#{type}" do
          it "returns the type for the column" do
            expect(subject.type_for_attribute(attribute_name.to_s)).to eq(active_record_type.new)
          end
        end
      end

      it_returns_the_type_for_the_attribute "default behavior", :string_type, ActiveRecord::Type::String
      it_returns_the_type_for_the_attribute :string, :color, ActiveRecord::Type::String
      it_returns_the_type_for_the_attribute :integer, :price, ActiveRecord::Type::Integer
      it_returns_the_type_for_the_attribute :float, :weight, ActiveRecord::Type::Float
      it_returns_the_type_for_the_attribute :datetime, :build_timestamp, ActiveRecord::Type::DateTime
      it_returns_the_type_for_the_attribute :date, :released_at, ActiveRecord::Type::Date
      it_returns_the_type_for_the_attribute :boolean, :published, ActiveRecord::Type::Boolean
    else
      subject { Product }

      it "is not defined" do
        expect(subject).to_not respond_to(:type_for_attribute)
      end
    end
  end

  describe "#column_for_attribute" do
    if ActiveRecord::VERSION::STRING.to_f >= 4.2

      def self.it_returns_the_properly_typed_column(type, attribute_name, cast_type_class)
        context "#{type}" do
          subject { Product.column_for_attribute(attribute_name) }
          it "returns a column with a #{type} cast type" do
            expect(subject).to be_a(ActiveRecord::ConnectionAdapters::Column)
            expect(subject.cast_type).to eq(cast_type_class.new)
          end
        end
      end

      it_returns_the_properly_typed_column :string, :color, ActiveRecord::Type::String
      it_returns_the_properly_typed_column :integer, :price, ActiveRecord::Type::Integer
      it_returns_the_properly_typed_column :boolean, :published, ActiveRecord::Type::Boolean
      it_returns_the_properly_typed_column :float, :weight, ActiveRecord::Type::Float
      it_returns_the_properly_typed_column :datetime, :build_timestamp, ActiveRecord::Type::DateTime
      it_returns_the_properly_typed_column :date, :released_at, ActiveRecord::Type::Date
      it_returns_the_properly_typed_column :decimal, :miles, ActiveRecord::Type::Decimal
      it_returns_the_properly_typed_column :array, :tags, ActiveRecord::Type::Value
      it_returns_the_properly_typed_column :hash, :reviews, ActiveRecord::Type::Value
      it "returns actual array and hash type columns back"
    else
      def self.it_returns_the_properly_typed_column(hstore_type, attribute_name, active_record_type)
        context "#{hstore_type}" do
          subject { Product.new.column_for_attribute(attribute_name) }
          it "returns a column with a #{hstore_type} cast type" do
            expect(subject).to be_a(ActiveRecord::ConnectionAdapters::Column)
            expect(subject.type).to eq(active_record_type)
          end
        end
      end

      it_returns_the_properly_typed_column :string, :color, :string
      it_returns_the_properly_typed_column :integer, :price, :integer
      it_returns_the_properly_typed_column :boolean, :published, :boolean
      it_returns_the_properly_typed_column :float, :weight, :float
      it_returns_the_properly_typed_column :time, :build_timestamp, :datetime
      it_returns_the_properly_typed_column :date, :released_at, :date
      it_returns_the_properly_typed_column :decimal, :miles, :decimal
      it "returns the proper type for array attributes"
    end
  end

  context "when assigning values it" do
    let(:product) { Product.new }

    it "correctly stores string values" do
      product.color = "blue"
      product.save
      product.reload
      expect(product.color).to eq "blue"
    end

    it "allows access to bulk set values via string before saving" do
      product.options = {
        "color" => "blue",
        "price" => 120
      }
      expect(product.color).to eq "blue"
      expect(product.price).to eq 120
    end

    it "allows access to bulk set values via :symbols before saving" do
      product.options = {
        color: "blue",
        price: 120
      }
      expect(product.color).to eq "blue"
      expect(product.price).to eq 120
    end

    it "correctly stores integer values" do
      product.price = 468
      product.save
      product.reload
      expect(product.price).to eq 468
    end

    it "correctly stores float values" do
      product.weight = 93.45
      product.save
      product.reload
      expect(product.weight).to eq 93.45
    end

    context "array values" do
      it "correctly stores nothing" do
        product.tags = nil
        product.save
        product.reload
        expect(product.tags).to be_nil
      end

      it "correctly stores strings" do
        product.tags = ["household", "living room", "kitchen"]
        product.save
        product.reload
        expect(product.tags).to eq ["household", "living room", "kitchen"]
      end

      it "correctly stores integers" do
        product.tags = [1, 2, "3"]
        product.save
        product.reload
        expect(product.tags).to eq [1, 2, "3"]
      end

      it "correctly stores hashes" do
        product.tags = [{ foo: "bar" }, { "baz" => 123 }]
        product.save
        product.reload
        expect(product.tags).to eq [{ foo: "bar" }, { "baz" => 123 }]
      end

      it "correctly stores non-arrays as array wrapped objects" do
        product.tags = "bar"
        product.save
        product.reload
        expect(product.tags).to eq ["bar"]
      end
    end

    context "hash values" do
      it "correctly stores nothing" do
        product.reviews = nil
        product.save
        product.reload
        expect(product.reviews).to be_nil
      end

      it "correctly stores stringy-keyed hash values" do
        product.reviews = { "user_123" => "4 stars", "user_994" => "3 stars" }
        product.save
        product.reload
        expect(product.reviews).to eq("user_123" => "4 stars", "user_994" => "3 stars")
      end

      it "correctly stores a variety of hash values" do
        product.reviews = { "user_123" => [1, 2], "user_994" => "stringy", foo: :bar, baz: 1, zoo: "zaz", hashy: { test: 1 } }
        product.save
        product.reload
        expect(product.reviews).to eq("user_123" => [1, 2], "user_994" => "stringy", foo: :bar, baz: 1, zoo: "zaz", hashy: { test: 1 })
      end

      it "correctly stores an object" do
        class Stuff
          attr_accessor :thing
        end

        stuff = Stuff.new
        stuff.thing = "1"

        product.reviews = { "stuff" => stuff }
        product.save
        product.reload

        expect(product.reviews["stuff"].thing).to eq(stuff.thing)

        Object.send(:remove_const, :Stuff)
        product.reload

        expect { product.reviews }.to raise_error
      end

      it "raises an exception when trying to store a non-hash value" do
        expect do
          product.reviews = "hello"
        end.to raise_error(HstoreAccessor::Serialization::InvalidDataTypeError)
      end
    end

    context "multipart values" do
      it "stores multipart dates correctly" do
        product.update_attributes!(
          "released_at(1i)" => "2014",
          "released_at(2i)" => "04",
          "released_at(3i)" => "14"
        )
        product.reload
        expect(product.released_at).to eq(Date.new(2014, 4, 14))
      end
    end

    it "correctly stores time values" do
      timestamp = Time.now - 10.days
      product.build_timestamp = timestamp
      product.save
      product.reload
      expect(product.build_timestamp.to_i).to eq timestamp.to_i
    end

    it "correctly stores date values" do
      datestamp = Date.today - 9.days
      product.released_at = datestamp
      product.save
      product.reload
      expect(product.released_at.to_s).to eq datestamp.to_s
      expect(product.released_at).to eq datestamp
    end

    it "correctly stores decimal values" do
      decimal = BigDecimal.new("9.13370009001")
      product.miles = decimal
      product.save
      product.reload
      expect(product.miles.to_s).to eq decimal.to_s
      expect(product.miles).to eq decimal
    end

    context "correctly stores boolean values" do
      it "when string 'true' is passed" do
        product.popular = "true"
        product.save
        product.reload
        expect(product.popular).to be true
      end

      it "when a real boolean is passed" do
        product.popular = true
        product.save
        product.reload
        expect(product.popular).to be true
      end
    end

    it "setters call the _will_change! method of the store attribute" do
      expect(product).to receive(:options_will_change!)
      product.color = "green"
    end

    describe "type casting" do
      it "type casts integer values" do
        product.price = "468"
        expect(product.price).to eq 468
      end

      it "type casts float values" do
        product.weight = "93.45"
        expect(product.weight).to eq 93.45
      end

      it "type casts time values" do
        timestamp = Time.now - 10.days
        product.build_timestamp = timestamp.to_s
        expect(product.build_timestamp.to_i).to eq timestamp.to_i
      end

      it "type casts date values" do
        datestamp = Date.today - 9.days
        product.released_at = datestamp.to_s
        expect(product.released_at).to eq datestamp
      end

      it "type casts decimal values" do
        product.miles = "1.337900129339202"
        expect(product.miles).to eq BigDecimal.new("1.337900129339202")
      end

      it "type casts boolean values" do
        ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.each do |value|
          product.popular = value
          expect(product.popular).to be true

          product.published = value
          expect(product.published).to be true
        end

        ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.each do |value|
          product.popular = value
          expect(product.popular).to be false

          product.published = value
          expect(product.published).to be false
        end
      end
    end

    context "extended getters and setters" do
      before do
        class Product
          alias_method :set_color, :color=
          alias_method :get_color, :color

          def color=(value)
            super(value.upcase)
          end

          def color
            super.try(:downcase)
          end
        end
      end

      after do
        class Product
          alias_method :color=, :set_color
          alias_method :color, :get_color
        end
      end

      context "setters" do
        it "can be wrapped" do
          product.color = "red"
          expect(product.options["color"]).to eq("RED")
        end
      end

      context "getters" do
        it "can be wrapped" do
          product.color = "GREEN"
          expect(product.color).to eq("green")
        end
      end
    end
  end

  describe "dirty tracking" do
    let(:product) { Product.new }

    it "<attr>_changed? should return the expected value" do
      expect(product.color_changed?).to be false
      product.color = "ORANGE"
      expect(product.price_changed?).to be false
      expect(product.color_changed?).to be true
      product.save
      expect(product.color_changed?).to be false
      product.color = "ORANGE"
      expect(product.color_changed?).to be false

      expect(product.price_changed?).to be false
      product.price = 100
      expect(product.price_changed?).to be true
      product.save
      expect(product.price_changed?).to be false
      product.price = "100"
      expect(product.price).to be 100
      expect(product.price_changed?).to be false
    end

    describe "#<attr>_will_change!" do
      it "tells ActiveRecord the hstore attribute has changed" do
        expect(product).to receive(:options_will_change!)
        product.color_will_change!
      end
    end

    describe "#<attr>_was" do
      it "returns the expected value" do
        product.color = "ORANGE"
        product.save
        product.color = "GREEN"
        expect(product.color_was).to eq "ORANGE"
      end

      it "works when the hstore attribute is nil" do
        product.options = nil
        product.save
        product.color = "green"
        expect { product.color_was }.to_not raise_error
      end
    end

    describe "#<attr>_change" do
      it "returns the old and new values" do
        product.color = "ORANGE"
        product.save
        product.color = "GREEN"
        expect(product.color_change).to eq %w(ORANGE GREEN)
      end

      context "hstore attribute was nil" do
        it "returns old and new values" do
          product.options = nil
          product.save!
          green = product.color = "green"
          expect(product.color_change).to eq([nil, green])
        end
      end

      context "other hstore attributes were persisted" do
        it "returns nil" do
          product.price = 5
          product.save!
          product.price = 6
          expect(product.color_change).to be_nil
        end
      end

      context "not persisted" do
        it "returns nil when there are no changes" do
          expect(product.color_change).to be_nil
        end
      end
    end

    describe "#reset_<attr>!" do
      before do
        allow(ActiveSupport::Deprecation).to receive(:warn)
      end

      if ActiveRecord::VERSION::STRING.to_f >= 4.2
        it "displays a deprecation warning" do
          expect(ActiveSupport::Deprecation).to receive(:warn)
          product.reset_color!
        end
      else
        it "does not display a deprecation warning" do
          expect(ActiveSupport::Deprecation).to_not receive(:warn)
          product.reset_color!
        end
      end

      it "restores the attribute" do
        expect(product).to receive(:restore_color!)
        product.reset_color!
      end
    end

    describe "#restore_<attr>!" do
      it "restores the attribute" do
        product.color = "red"
        product.restore_color!
        expect(product.color).to be_nil
      end

      context "persisted" do
        it "restores the attribute" do
          green = product.color = "green"
          product.save!
          product.color = "red"
          product.restore_color!
          expect(product.color).to eq(green)
        end
      end
    end
  end
end
