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

```ruby
class Product < ActiveRecord::Base

  hstore_accessor :options,
    color: :string,
    weight: :integer,
    

end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
