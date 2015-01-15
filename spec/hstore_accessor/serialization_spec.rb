require "spec_helper"

describe HstoreAccessor::Serialization do
  describe "#migrate_array" do
    let(:old_array) { "foo||;||bar||;||baz" }
    let(:new_array) { YAML.dump(%w(foo bar baz)) }

    it "converts a serialized array into YAML" do
      expect(subject.migrate_array(old_array)).to eq(new_array)
    end

    it "leaves nil as nil" do
      expect(subject.migrate_array(nil)).to be_nil
    end
  end

  describe "#migrate_hash" do
    let!(:old_hash) { { foo: "bar" }.to_json }
    let!(:new_hash) { YAML.dump("foo" => "bar") }

    it "converts hashes serialized as json into YAML" do
      expect(subject.migrate_hash(old_hash)).to eq(new_hash)
    end

    it "leaves nil as nil" do
      expect(subject.migrate_hash(nil)).to be_nil
    end
  end
end
