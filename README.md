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
Product.tags_contains("kitchen")                  # tags containing a
single value
Product.tags_contains(["housewares", "kitchen"])  # tags containing a
number of values
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
