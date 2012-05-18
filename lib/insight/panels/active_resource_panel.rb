require "digest"

module Insight
  class ActiveResourcePanel < Panel
    require 'insight/panels/active_resource_panel/query'
    #require "insight/panels/sql_panel/panel_app"
    #require "insight/panels/sql_panel/query"

    def initialize(app)
      super
      probe(self) do
        instrument "ActiveResource::Connection" do
          instance_probe :request
        end
      end
      table_setup("active_resource_requests")
    end

    def after_detect(method_call, timing, arguments, results)
      body = "<no body>"
      if results.respond_to? :body
        body = results.body
      end
      store(@env, RequestResult.new(arguments[0], arguments[1..-1], timing.duration, method_call.backtrace[0..5], body))
    end

    def total_time(queries)
      (queries.inject(0) do |memo, query|
        memo + query.time
      end)
    end

    def name
      "active_record"
    end

    def heading_for_request(number)
      queries = retrieve(number)
      "ARes: #{queries.size} Queries (%.2fms)" % total_time(queries)
    end

    def content_for_request(number)
      queries = retrieve(number)
      logger.debug{ "ARes: #{queries.inspect}" }
      render_template "panels/active_resource", :queries => queries
    end
  end
end
