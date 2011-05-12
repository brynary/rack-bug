require 'sqlite3'
require 'rack/bug'


class Rack::Bug::SpeedTracerPanel
  class Database
    class << self
      def db
        if @db.nil?
          open_database
        end
        return @db
      end

      def open_database
        @db = SQLite3::Database.new("rack_bug.sqlite")
      end

      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          open_database if forked
        end
      end
    end

    def db
      self.class.db
    end

    def initialize(table_name)
      @table_name = table_name
      if(db.execute("select * from sqlite_master where name = ?", table_name).empty?)
        db.execute("create table #@table_name ( key varchar primary key, value varchar )")
      end
      if Rails.logger
        Rails.logger.debug{ "Initializing a table called #{table_name}" }
      end
    end

    def [](key)
      rows = db.execute("select value from #@table_name where key = ?", key.to_s)
      if rows.empty?
        return nil
      else
        Marshal.load(rows.first.first)
      end
    end

    def []=(key, value)
      db.execute("insert or replace into #@table_name ( key, value ) values ( ?, ? )", key.to_s, Marshal.dump(value))
    end

    def keys
      db.execute("select key from #@table_name").flatten
    end
    
    def to_a
      db.execute("select key, value from #@table_name").map do |key, value|
        [key, Marshal.load(value)]
      end
    end
  end
end

