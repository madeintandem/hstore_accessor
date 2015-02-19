require "active_support"
require "active_record"
require "hstore_accessor/version"

if ::ActiveRecord::VERSION::STRING.to_f >= 4.2
  require "hstore_accessor/active_record_4.2/type_helpers"
else
  require "hstore_accessor/active_record_pre_4.2/type_helpers"
  require "hstore_accessor/active_record_pre_4.2/time_helper"
end

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
