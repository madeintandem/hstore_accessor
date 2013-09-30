require "spec_helper"
require "active_support/all"

FIELDS = {
  color: :string,
  price: :integer,
  weight: { data_type: :float, store_key: "w" },
  popular: :boolean,
  build_timestamp: :time,
  tags: :array,
  reviews: :hash,
  released_at: :date
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

  context "nil values" do
    let!(:timestamp) { Time.now }
    let!(:datestamp) { Date.today }
    let!(:product)   { Product.new }
    let!(:product_a) { Product.create(color: "green",  price: 10, weight: 10.1, tags: ["tag1", "tag2", "tag3"], popular: true,  build_timestamp: (timestamp - 10.days), released_at: (datestamp - 8.days)) }

    FIELDS.keys.each do |field|
      it "reponds with nil when #{field} is not set" do
        expect(product.send(field)).to be_nil
      end
    end

    FIELDS.keys.each do |field|
      it "reponds with nil when #{field} is set back to nil after being set initially" do
        product_a.send("#{field}=", nil)
        expect(product_a.send(field)).to be_nil
      end
    end

  end
  describe "scopes" do

    let!(:timestamp) { Time.now }
    let!(:datestamp) { Date.today }
    let!(:product_a) { Product.create(color: "green",  price: 10, weight: 10.1, tags: ["tag1", "tag2", "tag3"], popular: true,  build_timestamp: (timestamp - 10.days), released_at: (datestamp - 8.days)) }
    let!(:product_b) { Product.create(color: "orange", price: 20, weight: 20.2, tags: ["tag2", "tag3", "tag4"], popular: false, build_timestamp: (timestamp - 5.days), released_at: (datestamp - 4.days)) }
    let!(:product_c) { Product.create(color: "blue",   price: 30, weight: 30.3, tags: ["tag3", "tag4", "tag5"], popular: true,  build_timestamp: timestamp, released_at: datestamp) }

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

    context "for array fields support" do

      it "equality" do
        expect(Product.tags_eq(["tag1", "tag2", "tag3"]).to_a).to eq [product_a]
      end

      it "contains" do
        expect(Product.tags_contains("tag2").to_a).to eq [product_a, product_b]
        expect(Product.tags_contains(["tag2", "tag3"]).to_a).to eq [product_a, product_b]
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
      expect(product.reviews).to eq({ "user_123" => "4 stars", "user_994" => "3 stars" })
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

    it "setters call the _will_change! method of the store attribute" do
      product.should_receive(:options_will_change!)
      product.color = "green"
    end

  end

end
