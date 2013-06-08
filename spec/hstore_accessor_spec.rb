require "spec_helper"
require "active_support/all"

class Product

  include HstoreAccessor

  attr_accessor :options

  hstore_accessor :options,
    color: :string,
    price: :integer,
    weight: :float,
    tags: :array,
    reviews: :hash

  def initialize
    @options = {}
  end

  def options_will_change!; end

end

describe HstoreAccessor do

  let(:product) { Product.new }

  it "creates getters for the hstore fields" do
    [:color, :price, :weight, :tags, :reviews].each do |field|
      expect(product).to respond_to(field)
    end
  end

  it "creates setters for the hstore fields" do
    [:color, :price, :weight, :tags, :reviews].each do |field|
      expect(product).to respond_to(:"#{field}=")
    end
  end

  it "creates scopes for the hstore fields"

  it "raises an InvalidDataTypeError if an invalid type is specified" do
    expect do
      class FakeModel
        include HstoreAccessor
        hstore_accessor :foo, bar: :baz
      end
    end.to raise_error(HstoreAccessor::InvalidDataTypeError)
  end

  it "setters call the _will_change! method of the store attribute" do
    product.should_receive(:options_will_change!)
    product.color = "green"
  end

  it "correctly stores string values" do
    product.color = "blue"
    expect(product.color).to eq "blue"
  end

  it "correctly stores integer values" do
    product.price = 468
    expect(product.price).to eq 468
  end

  it "correctly stores float values" do
    product.weight = 93.45
    expect(product.weight).to eq 93.45
  end

  it "correctly stores array values" do
    product.tags = ["household", "living room", "kitchen"]
    expect(product.tags).to eq ["household", "living room", "kitchen"]
  end

  it "correctly stores hash values" do
    product.reviews = { "user_123" => "4 stars", "user_994" => "3 stars" }
    expect(product.reviews).to eq({ "user_123" => "4 stars", "user_994" => "3 stars" })
  end

end
