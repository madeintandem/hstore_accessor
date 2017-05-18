# HstoreAccessor

## Starting a new project? Use [Jsonb Accessor](https://github.com/devmynd/jsonb_accessor) instead! It has more features and is better maintained.

## Description
Hstore Accessor allows you to treat fields on an hstore column as though they were actual columns being picked up by ActiveRecord. This is especially handy when trying to avoid sparse columns while making use of [single table inheritence](#single-table-inheritance). Hstore Accessor currently supports ActiveRecord versions 4.0, 4.1, 4.2, 5.0, and 5.1.


## Table of Contents

* [Installation](#installation)
* [Setup](#setup)
* [ActiveRecord methods generated for fields](#activerecord-methods-generated-for-fields)
* [Scopes](#scopes)
  * [String Fields](#string-fields)
  * [Integer, Float, and Decimal Fields](#integer-float-decimal-fields)
  * [Datetime Fields](#datetime-fields)
  * [Date Fields](#date-fields)
  * [Array Fields](#array-fields)
  * [Boolean Fields](#boolean-fields)
* [Single Table Inheritence](#single-table-inheritance)
* [Upgrading](#upgrading)
* [Contributing](#contributing)
  - [Basics](#basics)
  - [Developing Locally](#developing-locally)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "hstore_accessor", "~> 1.1"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hstore_accessor

## Setup

The `hstore_accessor` method accepts the name of the hstore column you'd
like to use and a hash with keys representing fields and values
indicating the type to be stored in that field.  The available types
are: `string`, `integer`, `float`, `decimal`, `datetime`, `date`, `boolean`, `array`, and `hash`. It is available on an class that inherits from `ActiveRecord::Base`.

```ruby
class Product < ActiveRecord::Base
  hstore_accessor :options,
    color: :string,
    weight: :integer,
    price: :float,
    built_at: :datetime,
    build_date: :date,
    tags: :array, # deprecated
    ratings: :hash # deprecated
    miles: :decimal
end
```

Now you can interact with the fields stored in the hstore directly.

```ruby
product = Product.new
product.color = "green"
product.weight = 34
product.price = 99.95
product.built_at = Time.now - 10.days
product.build_date = Date.today
product.popular = true
product.tags = %w(housewares kitchen) # deprecated
product.ratings = { user_a: 3, user_b: 4 } # deprecated
product.miles = 3.14
```

Reading these fields works as well.

```ruby
product.color # => "green"
product.price  # => 99.95
```

In order to reduce the storage overhead of hstore keys (especially when
indexed) you can specify an alternate key.

```ruby
hstore_accessor :options,
  color: { data_type: :string, store_key: "c" },
  weight: { data_type: :integer, store_key: "w" }
```

In the above example you can continue to interact with the fields using
their full name but when saved to the database the field will be set
using the `store_key`.

Additionally, dirty tracking is implemented in the same way that normal
`ActiveRecord` fields work.

```ruby
product.color          #=> "green"
product.color = "blue"
product.changed?       #=> true
product.color_changed? #=> true
product.color_was      #=> "green"
product.color_change  #=> ["green", "blue"]
```

## ActiveRecord methods generated for fields

```ruby
class Product < ActiveRecord::Base
  hstore_accessor :data, field: :string
end
```

* `field`
* `field=`
* `field?`
* `field_changed?`
* `field_was`
* `field_change`
* `reset_field!`
* `restore_field!`
* `field_will_change!`

Overriding methods is supported, with access to the original Hstore Accessor implementation available via `super`.

Additionally, there is also `hstore_metadata_for_<fields>` on both the class and instances. `column_for_attribute` will also return a column object for an Hstore Accessor defined field. If you're using ActiveRecord 4.2, `type_for_attribute` will return a type object for Hstore Accessor defined fields the same as it does for actual columns. 

## Scopes

The `hstore_accessor` macro also creates scopes for `string`, `integer`,
`float`, `decimal`, `time`, `date`, `boolean`, and `array` fields.

### String Fields

For `string` types, a `with_<key>` scope is created which checks for
equality.

```ruby
Product.with_color("green")
```

### Integer, Float, Decimal Fields

For `integer`, `float` and `decimal` types five scopes are created:

```ruby
Product.price_lt(240.00)  # price less than
Product.price_lte(240.00) # price less than or equal to
Product.price_eq(240.00)  # price equal to
Product.price_gte(240.00) # price greater than or equal to
Product.price_gt(240.00)  # price greater than
```

### Datetime Fields

For `datetime` fields, three scopes are created:

```ruby
Product.built_at_before(Time.now)         # built before the given time
Product.built_at_eq(Time.now - 10.days)   # built at an exact time
Product.built_at_after(Time.now - 4.days) # built after the given time
```

### Date Fields

For `date` fields, three scopes are created:

```ruby
Product.build_date_before(Date.today)         # built before the given date
Product.build_date_eq(Date.today - 10.days)   # built at an exact date
Product.built_date_after(Date.today - 4.days) # built after the given date
```

### Array Fields

*Note: the array field type is deprecated. It is available in version 0.9.0 but not > 1.0.0*

For `array` types, two scopes are created:

```ruby
Product.tags_eq(%w(housewares kitchen))       # tags equaling
Product.tags_contains("kitchen")              # tags containing a single value
Product.tags_contains(%w(housewares kitchen)) # tags containing a number of values
```

### Boolean Fields

Two scopes are created for `boolean` fields:

```ruby
Product.is_popular  # => when popular is set to true
Product.not_popular # => when popular is set to false
```

Predicate methods are also available on instances:

```ruby
product = Product.new(popular: true)
product.popular? # => true
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

## Upgrading
Upgrading from version 0.6.0 to 0.9.0 should be fairly painless. If you were previously using a `time` type fields, simply change it to `datetime` like so:

```ruby
# Before...
hstore_accessor :data, published_at: :time
# After...
hstore_accessor :data, published_at: :datetime
```

While the `array` and `hash` types are available in version 0.9.0, they are deprecated and are not available in 1.0.0.

## Contributing
### Basics
1. [Fork it](https://github.com/devmynd/hstore_accessor/fork) 
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write code _and_ tests
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

### Developing Locally
Before you make your pull requests, please make sure you style is in line with our Rubocop settings and that all of the tests pass.

1. `bundle install`
2. `appraisal install`
3. Make sure Postgres is installed and running
4. `appraisal rspec` to run all the tests
5. `rubocop` to check for style
