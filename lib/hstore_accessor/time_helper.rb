module HstoreAccessor
  module TimeHelper

    # There is a bug in ActiveRecord::ConnectionAdapters::Column#string_to_time
    # which drops the timezone. This has been fixed, but not released.
    # This method includes the fix. See: https://github.com/rails/rails/pull/12290

    def self.string_to_time(string)
      return string unless string.is_a?(String)
      return nil if string.empty?

      time_hash = Date._parse(string)
      time_hash[:sec_fraction] = ActiveRecord::ConnectionAdapters::Column.send(:microseconds, time_hash)
      (year, mon, mday, hour, min, sec, microsec, offset) = *time_hash.values_at(:year, :mon, :mday, :hour, :min, :sec, :sec_fraction, :offset)

      # Treat 0000-00-00 00:00:00 as nil.
      return nil if year.nil? || (year == 0 && mon == 0 && mday == 0)

      if offset
        time = Time.utc(year, mon, mday, hour, min, sec, microsec) rescue nil
        return nil unless time

        time -= offset
        ActiveRecord::Base.default_timezone == :utc ? time : time.getlocal
      else
        Time.public_send(ActiveRecord::Base.default_timezone, year, mon, mday, hour, min, sec, microsec) rescue nil
      end
    end

  end
end
