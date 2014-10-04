require "spec_helper"
require "active_support/all"

FIELDS = {
  color: :string,
  price: :integer,
  published: { data_type: :boolean, store_key: "p" },
  weight: { data_type: :float, store_key: "w" },
  popular: :boolean,
  build_timestamp: :time,
  tags: :array,
  reviews: :hash,
  released_at: :date,
  miles: :decimal
}

class Product < ActiveRecord::Base
  hstore_accessor :options, FIELDS
end

describe HstoreAccessor do
  context "macro" do
    let(:product) { Product.new }

    FIELDS.keys.each do |field|
      it "creates a getter for the hstore field: #{field}" do
        expect(product).to respond_to(field)
      end
    end

    FIELDS.keys.each do |field|
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

  context "#__hstore_metadata_for_*" do
    let(:product) { Product.new }

    it "returns the metadata hash for the specified field" do
      expect(product.hstore_metadata_for_options).to eq FIELDS
    end
  end

  context "nil values" do
    let!(:timestamp) { Time.now }
    let!(:datestamp) { Date.today }
    let!(:product) { Product.new }
    let!(:product_a) { Product.create(color: "green", price: 10, weight: 10.1, tags: %w(tag1 tag2 tag3), popular: true, build_timestamp: (timestamp - 10.days), released_at: (datestamp - 8.days), miles: BigDecimal.new("9.133790001")) }

    FIELDS.keys.each do |field|
      it "responds with nil when #{field} is not set" do
        expect(product.send(field)).to be_nil
      end
    end

    FIELDS.keys.each do |field|
      it "responds with nil when #{field} is set back to nil after being set initially" do
        product_a.send("#{field}=", nil)
        expect(product_a.send(field)).to be_nil
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

      it "contains" do
        expect(Product.tags_contains("tag2").to_a).to eq [product_a, product_b]
        expect(Product.tags_contains(%w(tag2 tag3)).to_a).to eq [product_a, product_b]
        expect(Product.tags_contains(%w(tag1 tag2 tag3)).to_a).to eq [product_a]
        expect(Product.tags_contains(%w(tag1 tag2 tag3 tag4)).to_a).to eq []
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

    it "correctly stores array values" do
      product.tags = ["household", "living room", "kitchen"]
      product.save
      product.reload
      expect(product.tags).to eq ["household", "living room", "kitchen"]
    end

    it "correctly stores hash values" do
      product.reviews = { "user_123" => "4 stars", "user_994" => "3 stars" }
      product.save
      product.reload
      expect(product.reviews).to eq("user_123" => "4 stars", "user_994" => "3 stars")
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

    it "<attr>_was should return the expected value" do
      product.color = "ORANGE"
      product.save
      product.color = "GREEN"
      expect(product.color_was).to eq "ORANGE"
    end

    it "<attr>_change should return the expected value" do
      product.color = "ORANGE"
      product.save
      product.color = "GREEN"
      expect(product.color_change).to eq %w(ORANGE GREEN)
    end
  end
end
