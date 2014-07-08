#require 'rack-insight'
require 'sqlite3'
require 'base64'

module Rack::Insight
  class Database

    module EigenClient
      def self.included(base)
        base.send(:attr_accessor, :table)
        base.send(:attr_accessor, :key_sql_template)
      end
    end

    # Classes including this module must define the following structure:
    #    class FooBar
    #      include Rack::Insight::Database
    #      class << self
    #        attr_accessor :has_table
    #      end
    #      # Setting as below is only required when not using a table (Why are you including this module then?)
    #      # self.has_table = false
    #    end
    # TODO: Move the has_table definition into this module's included hook.
    module RequestDataClient
      def key_sql_template(sql)
        self.class.key_sql_template = sql
      end

      def table_setup(name, *keys)
        self.class.has_table = true
        self.class.table = DataTable.new(name, *keys)
        if keys.empty?
          self.class.key_sql_template = ''
        end
        self.class.table
      end

      def store(env, *keys_and_value)
        return if env.nil?
        request_id = env["rack-insight.request-id"]
        return if request_id.nil?

        value = keys_and_value[-1]
        keys = keys_and_value[0...-1]

        #puts "value: #{value}"
        #puts "keys: #{keys}"
        #puts "table: #{self.class.table.inspect}"
        #puts "@key_sql_template: #{self.class.key_sql_template}"
        #puts "class: #{self.class.inspect}"
        self.class.table.store(request_id, value, self.class.key_sql_template % keys)
      end

      def retrieve(request_id)
        self.class.table.for_request(request_id)
      end

      def count(request_id)
        self.class.table.count_for_request(request_id)
      end

      def table_length
        self.class.table.length
      end
    end

    class << self
      include Logging

      def database_path=(value)
        @database_path = value || "rack-insight.sqlite"
      end

      def database_path
        @database_path
      end

      def db
        @db ||= open_database
      end

      def reset
        @db = nil
      end

      def open_database
        @db = SQLite3::Database.new(database_path)
        @db.busy_timeout = 10000
        @db.execute("pragma foreign_keys = on")
        @db
      rescue StandardError => ex
        msg = "Issue while loading SQLite DB:" + [ex.class, ex.message, ex.backtrace[0..4]].inspect
        logger.error{ msg }

        return {}
      end

      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          Rack::Insight::Database::open_database if forked
        end
      end
    end

    class Table
      include Logging

      def db
        Rack::Insight::Database.db
      end

      def create_keys_clause
        "#{@keys.map{|key| "#{key} varchar"}.join(", ")}"
      end

      def create_sql
        "create table #@table_name ( id integer primary key, #{create_keys_clause} )"
      end

      def execute(*args)
        #logger.info{ ins_args = args.inspect; "(#{[ins_args.length,120].min}/#{ins_args.length})" + ins_args[0..120] } if verbose(:debug)
        db.execute(*args)
      end

      def initialize(table_name, *keys)
        @table_name = table_name
        @keys = keys
        if(execute("select * from sqlite_master where name = ?", table_name).empty?)
          logger.info{ "Initializing a table called #{table_name}" } if verbose(:med)
          execute(create_sql)
        end
      end

      def select(which_sql, condition_sql)
        execute("select #{which_sql} from #@table_name where #{condition_sql}")
      end

      def count(condition_sql)
        execute("select count(*) from #@table_name where #{condition_sql}")
      end

      def fields_sql
        "#{@keys.join(",")}"
      end

      def insert(values_sql)
        execute("insert into #@table_name(#{fields_sql}) values (#{values_sql})")
      end

      def keys(name)
        execute("select #{name} from #@table_name").flatten
      end

      def length(where = "1 = 1")
        execute("select count(1) from #@table_name where #{where}").first.first
      end

      def to_a
        execute("select * from #@table_name")
      end
    end

    class RequestTable < Table
      def initialize()
        super("requests", "method", "url", "date")
      end

      def store(method, url)
        result = insert("'#{method}', '#{url}', #{Time.now.to_i}")
        db.last_insert_row_id
      end

      def last_request_id
        execute("select max(id) from #@table_name").first.first
      end

      def sweep
        execute("delete from #@table_name where date < #{Time.now.to_i - (60 * 60 * 12)}")
      end
    end

    require 'yaml'
    class DataTable < Table
      def initialize(name, *keys)
        super(name, *(%w{request_id} + keys + %w{value}))
      end

      def create_keys_clause
        non_request_keys = @keys - %w"request_id"
        sql = non_request_keys.map{|key| "#{key} varchar"}.join(", ")
        sql += ", request_id references requests(id) on delete cascade"
        sql
      end

      def store(request_id, value, keys_sql = "")
        sql = "'#{encode_value(value)}'"
        sql = keys_sql + ", " + sql unless keys_sql.empty?
        sql = "#{request_id}, #{sql}"
        insert(sql)
      end

      # We sometimes get errors in the encoding and decoding, and they could be from any number of root causes.
      # This will allow those root causes to be exposed at the top layer by wrapping all errors in a Rack::Insight
      # namespaced error class, which will be rescued higher up the stack.
      module ErrorWrapper
        def new(parent, message = '')
          ex = super("#{message}#{parent.class}: #{parent.message}")
          ex.set_backtrace parent.backtrace
          ex
        end
      end

      class EncodingError < StandardError
        extend ErrorWrapper
      end

      class DecodingError < StandardError
        extend ErrorWrapper
      end

      def encode_value(value)
        Base64.encode64(YAML.dump(value))
      rescue Exception => ex
        wrapped = EncodingError.new(ex, "Rack::Insight::Database#encode_value failed with error: ")
        logger.error(wrapped)
        raise wrapped if Rack::Insight::Config.database[:raise_encoding_errors]
      end

      def decode_value(value)
        YAML.load(Base64.decode64(value))
      rescue Exception => ex
        wrapped = DecodingError.new(ex, "Rack::Insight::Database#decode_value failed with error: ")
        logger.error(wrapped)
        raise wrapped if Rack::Insight::Config.database[:raise_decoding_errors]
      end

      def retrieve(key_sql)
        select("value", key_sql).map{|value| decode_value(value.first)}
      end

      def count_entries(key_sql)
        count(key_sql).first.first
      end

      def for_request(id)
        retrieve("request_id = #{id}")
      end

      def count_for_request(id)
        count_entries("request_id = #{id}")
      end

      def to_a
        super.map do |row|
          row[-1] = decode_value(row[-1])
        end
      end
    end
  end
end
