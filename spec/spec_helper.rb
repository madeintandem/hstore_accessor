require "hstore_accessor"

ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  database: "hstore_accessor",
  username: "root"
)

ActiveRecord::Base.connection.execute("CREATE EXTENSION hstore;") rescue ActiveRecord::StatementInvalid
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS products;")

ActiveRecord::Base.connection.create_table(:products) do |t|
  t.hstore :options
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.after do
    Product.delete_all
  end
end
