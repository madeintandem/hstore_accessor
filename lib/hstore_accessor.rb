require "active_support"
require "active_record"
require "hstore_accessor/version"

if ::ActiveRecord::VERSION::STRING.to_f >= 5.0
  require "hstore_accessor/active_record_5.0/type_helpers"
elsif ::ActiveRecord::VERSION::STRING.to_f >= 4.2 && ::ActiveRecord::VERSION::STRING.to_f < 5.0
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

  # Rails 7.2 removed ActiveSupport::Deprecation.warn; use a gem-owned instance instead.
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("2.0", "HstoreAccessor")
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(HstoreAccessor)
end
