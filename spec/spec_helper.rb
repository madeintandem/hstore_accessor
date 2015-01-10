require "hstore_accessor"
require "database_cleaner"
require "shoulda-matchers"

DatabaseCleaner.strategy = :truncation

RSpec.configure do |config|
  config.mock_with :rspec

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

  ActiveRecord::Base.connection.create_table(:products) do |t|
    t.hstore :options
    t.hstore :data

    t.string :string_type
    t.integer :integer_type
    t.boolean :boolean_type
    t.float :float_type
    t.time :time_type
    t.string :array_type, array: true
    t.date :date_type
    t.datetime :datetime_type
    t.decimal :decimal_type
  end
end
