# HstoreAccessor

PostgreSQL provides an hstore data type for storing arbitrarily complex
structures in a column.  ActiveRecord 4.0 supports Hstore but casts all
valus in the store to a string.  Further, ActiveRecord does not provide
discrete fields to access values directly in the hstore column.  The
HstoreAccessor gem solves both of these issues.

## Installation

Add this line to your application's Gemfile:

    gem 'hstore_accessor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hstore_accessor

## Usage

### Setup

The `hstore_accessor` method accepts the name of the hstore column you'd
like to use and a hash with keys representing fields and values
indicating the type to be stored in that field.  The available types
are: `string`, `integer`, `float`, `array`, and `hash`.

```ruby
class Product < ActiveRecord::Base

  hstore_accessor :options,
    color: :string,
    weight: :integer,
    price: :float,
    tags: :array,
    ratings: :hash

end
```

Now you can interact with the fields stored in the hstore directly.

```ruby
p = Product.new
p.color = "green"
p.weight = 34
p.price = 99.95
p.tags = ["housewares", "kitchen"]
p.ratings = { user_a: 3, user_b: 4 }
```

Reading these fields works as well.

```ruby
p.color #=> "green
p.tags #=> ["housewares", "kitchen"] 
```

### Scopes

The `hstore_accessor` macro also creates scopes for `string`, `integer`,
`float`, and `array` fields.

For `string` types, a `with_<key>` scope is created which checks for
equality.

```ruby
Product.with_color("green")
```

For `integer` and `float` types five scopes are created:

```ruby
Product.price_lt(240.00)    # price less than
Product.price_lte(240.00)   # price less than or equal to
Product.price_eq(240.00)    # price equal to
Product.price_gte(240.00)   # price greater than or equal to
Product.price_gt(240.00)    # price greater than
```

For `array` types, two scopes are created:

```ruby
Product.tags_eq(["housewares", "kitchen"])        # tags equaling
Product.tags_contains("kitchen")                  # tags containing a single value
Product.tags_contains(["housewares", "kitchen"])  # tags containing a number of values
```

### Single-table Inheritance

One of the big issues with `ActiveRecord` single-table inheritance (STI)
is sparse columns.  Essentially, as sub-types of the original table
diverge further from their parent more columns are left empty in a given
table.  Postgres' `hstore` type provides part of the solution in that
the values in an `hstore` column does not impose a structure - different
rows can have different values.

We set up our table with an hstore field:

```ruby
# db/migration/<timestamp>_create_players_table.rb
class CreateVehiclesTable < ActiveRecord::Migration
  def change
    create_table :vehicles do |t|
      t.string :make
      t.string :model
      t.integer :model_year
      t.string :type
      t.hstore :data
    end
  end
end
```

And for our models:

```ruby
# app/models/vehicle.rb
class Vehicle < ActiveRecord::Base
end

# app/models/vehicles/automobile.rb
class Automobile < Vehicle
  hstore_accessor :data,
    axle_count: :integer,
    weight: :float,
    engine_details: :hash
end

# app/models/vehicles/airplane.rb
class Airplane < Vehicle
  hstore_accessor :data,
    engine_type: :string,
    safety_rating: :integer,
    features: :hash
end
```

From here any attributes specific to any sub-class can be stored in the
`hstore` column avoiding sparse data.  Indices can also be created on
individual fields in an `hstore` column.

This approach was originally concieved by Joe Hirn in [this blog
post](http://www.devmynd.com/blog/2013-3-single-table-inheritance-hstore-lovely-combination).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
