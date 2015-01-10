require "active_support"
require "active_record"
require "hstore_accessor/version"
require "hstore_accessor/type_helpers"
require "hstore_accessor/time_helper"
require "hstore_accessor/serialization"
require "hstore_accessor/macro"
require "bigdecimal"

module HstoreAccessor
  extend ActiveSupport::Concern
  include Serialization
  include Macro
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, HstoreAccessor)
end
