require "hstore_accessor"
require "database_cleaner"

DatabaseCleaner.strategy = :truncation

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = :random

  config.before :suite do
    create_database
  end

  config.before do
    DatabaseCleaner.clean
  end
end

def create_database
  ActiveRecord::Base.establish_connection(
    adapter: "postgresql",
    database: "hstore_accessor",
    username: "postgres"
  )

  ActiveRecord::Base.connection.execute("CREATE EXTENSION hstore;") rescue ActiveRecord::StatementInvalid
  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS products;")
  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS product_categories;")

  ActiveRecord::Base.connection.create_table(:products) do |t|
    t.hstore :options
    t.hstore :data

    t.string :string_type
    t.integer :integer_type
    t.integer :product_category_id
    t.boolean :boolean_type
    t.float :float_type
    t.time :time_type
    t.date :date_type
    t.datetime :datetime_type
    t.decimal :decimal_type
  end

  ActiveRecord::Base.connection.create_table(:product_categories) do |t|
    t.hstore :options
  end
end
