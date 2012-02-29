require 'insight'
require 'sqlite3'
require 'base64'

module Insight
  class Database
    module RequestDataClient
      def key_sql_template(sql)
        @key_sql_template = sql
      end

      def table_setup(name, *keys)
        @table = DataTable.new(name, *keys)
        if keys.empty?
          @key_sql_template = ""
        end
      end

      def store(env, *keys_and_value)
        return if env.nil?
        request_id = env["insight.request-id"]
        return if request_id.nil?

        value = keys_and_value[-1]
        keys = keys_and_value[0...-1]

        @table.store(request_id, value, @key_sql_template % keys)
      end

      def retrieve(request_id)
        @table.for_request(request_id)
      end
      alias retreive retrieve #JDL cannot spell

      def table_length
        @table.length
      end
    end

    class << self
      include Logging

      def database_path=(value)
        @database_path = value
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
        @db.execute("pragma foreign_keys = on")
        @db
      rescue Object => ex
        msg = "Issue while loading SQLite DB:" + [ex.class, ex.message, ex.backtrace[0..4]].inspect
        logger.debug{ msg }

        return {}
      end

      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          open_database if forked
        end
      end
    end

    class Table
      include Logging

      def db
        Insight::Database.db
      end

      def create_keys_clause
        "#{@keys.map{|key| "#{key} varchar"}.join(", ")}"
      end

      def create_sql
        "create table #@table_name ( id integer primary key, #{create_keys_clause} )"
      end

      def execute(*args)
        logger.debug{ ins_args = args.inspect; "(#{[ins_args.length,120].min}/#{ins_args.length})" + ins_args[0..120] }
        db.execute(*args)
      end

      def initialize(table_name, *keys)
        @table_name = table_name
        @keys = keys
        if(execute("select * from sqlite_master where name = ?", table_name).empty?)
          execute(create_sql)

          logger.debug{ "Initializing a table called #{table_name}" }
        end
      end

      def select(which_sql, condition_sql)
        execute("select #{which_sql} from #@table_name where #{condition_sql}")
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

      def encode_value(value)
        Base64.encode64(YAML.dump(value))
      end

      def decode_value(value)
        YAML.load(Base64.decode64(value))
      end

      def retrieve(key_sql)
        select("value", key_sql).map{|value| decode_value(value.first)}
      end

      def for_request(id)
        retrieve("request_id = #{id}")
      end

      def to_a
        super.map do |row|
          row[-1] = decode_value(row[-1])
        end
      end
    end
  end
end

