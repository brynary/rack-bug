module Rack::Insight
  class SQLPanel

    class QueryResult
      include Rack::Insight::FilteredBacktrace

      attr_reader :sql
      attr_reader :time

      def initialize(sql, time, backtrace = [], result=nil)
        @sql = sql
        @time = time
        @backtrace = backtrace
        @result = result
        @results = nil
      end

      def result
        @results ||= execute
        return @results
      end

      def column_names
        if result.respond_to?(:fields)
          return result.fields
        else
          return result.fetch_fields.map{|col| col.name}
        end
      end

      def rows
        if result.respond_to?(:values)
          result.values
        else
          result.map do |row|
            row
          end
        end
      end

      def human_time
        "%.2fms" % (@time)
      end

      def inspectable?
        sql.strip =~ /^SELECT /i
      end

      #Downside is: we re-execute the SQL...
      def self.execute(sql)
        ActiveRecord::Base.connection.execute(sql)
      end

      def execute
        self.class.execute(@sql)
      end

      def valid_hash?(secret_key, possible_hash)
        hash = Digest::SHA1.hexdigest [secret_key, @sql].join(":")
        possible_hash == hash
      end
    end

    class ExplainResult < QueryResult
      def execute
        self.class.execute "EXPLAIN #{@sql}"
      end
    end

    class ProfileResult < QueryResult
      def with_profiling
        result = nil
        begin
          self.class.execute("SET PROFILING=1")
          result = yield
        ensure
          self.class.execute("SET PROFILING=0")
        end
        return result
      end

      def execute
        with_profiling do
          super
          self.class.execute <<-SQL
              SELECT *
                FROM information_schema.profiling
               WHERE query_id = (SELECT query_id FROM information_schema.profiling ORDER BY query_id DESC LIMIT 1)
          SQL
        end
      end
    end
  end
end
