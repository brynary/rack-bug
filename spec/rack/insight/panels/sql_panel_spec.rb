require 'spec_helper'
require 'rack/insight/panels/sql_panel'

module Rack::Insight
  describe "SQLPanel" do
    before do
      mock_constant("ActiveRecord::ConnectionAdapters::MysqlAdapter")
      # TODO: Figure out why panel_classes work here but panel_files does not.
      #  reset_insight :panel_files => %w{sql_panel}
      reset_insight :panel_classes => [Rack::Insight::SQLPanel]
      app.insight_app.secret_key = "abc"
    end

    describe "heading" do
      it "displays the total SQL query count" do
        app.before_return do
          mock_method_call("ActiveRecord::ConnectionAdapters::MysqlAdapter", "execute", ["SELECT NOW();"])
        end
        response = get_via_rack "/"
        response.should have_heading("1 Queries")
      end

      it "displays the total SQL time" do
        app.before_return do
          mock_method_call("ActiveRecord::ConnectionAdapters::MysqlAdapter", "execute", ["SELECT NOW();"])
        end
        response = get_via_rack "/"
        response.should have_heading(/Queries \(\d+\.\d{2}ms\)/)
      end
    end

    describe "content" do
      it "displays each executed SQL query" do
        app.before_return do
          mock_method_call("ActiveRecord::ConnectionAdapters::MysqlAdapter", "execute", ["SELECT NOW();"])
        end
        response = get_via_rack "/"
        response.should have_row("div.panel_content#SqlPanel", "SELECT NOW();")
      end

      it "displays the time of each executed SQL query" do
        app.before_return do
          mock_method_call("ActiveRecord::ConnectionAdapters::MysqlAdapter", "execute", ["SELECT NOW();"])
        end
        response = get_via_rack "/"
        response.should have_row("div.panel_content#SqlPanel", "SELECT NOW();", TIME_MS_REGEXP)
      end
    end

    def stub_result(results = [[]])
      columns = results.first
      fields = columns.map { |c| double("field", :name => c) }
      rows = results[1..-1]

      result = double("result", :fetch_fields => fields)
      result.stub(:map).and_yield(rows)
      return result
    end

    def expect_query(sql, results)
      conn = double("connection")
      mock_constant("ActiveRecord::Base")
      ActiveRecord::Base.stub(:connection => conn)
      conn.should_receive(:execute).with(sql).and_return(stub_result(results))
    end

    describe "sql/execute" do
      it "displays the query results" do
        app.insight_app.secret_key = "abc"
        expect_query "SELECT username FROM users",
          [["username"],
            ["bryan"]]

        response = get_via_rack "/__insight__/sql/execute", {:query => "SELECT username FROM users",
          :hash => Digest::SHA1.hexdigest("abc:SELECT username FROM users")}, {:xhr => true}
        response.should contain("SELECT username FROM users")
        response.should be_ok
      end

      it "is forbidden when the hash is missing or wrong" do
        app.insight_app.secret_key='abc'

        lambda {
          get_via_rack "/__insight__/sql/execute", {:query => "SELECT username FROM users",
            :hash => "foobar"}, {:xhr => true}
        }.should raise_error(SecurityError)
      end

      it "is not available when the insight.secret_key is nil" do
        app.insight_app.secret_key = nil

        lambda {
          get_via_rack "/__insight__/sql/execute", {:query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"}, {:xhr => true}
        }.should raise_error(SecurityError)
      end

      it "is not available when the insight.secret_key is an empty string" do
        app.insight_app.secret_key = ""

        lambda {
          get_via_rack "/__insight__/sql/execute", {:query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"}, {:xhr => true}
        }.should raise_error(SecurityError)
      end
    end

    describe "sql/explain" do
      it "displays the query explain plan" do
        app.insight_app.secret_key = "abc"
        expect_query "EXPLAIN SELECT username FROM users",
          [["table"],
            ["users"]]


        response = get_via_rack "/__insight__/sql/explain", :query => "SELECT username FROM users",
          :hash => Digest::SHA1.hexdigest("abc:SELECT username FROM users")
        response.should contain("SELECT username FROM users")
        response.should be_ok
      end

      it "is forbidden when the hash is missing or wrong" do
        app.insight_app.secret_key='abc'

        lambda {
          get_via_rack "/__insight__/sql/explain", :query => "SELECT username FROM users",
          :hash => "foobar"
        }.should raise_error(SecurityError)
      end

      it "is not available when the insight.secret_key is nil" do
        app.insight_app.secret_key=nil

        lambda {
          get_via_rack "/__insight__/sql/explain", :query => "SELECT username FROM users",
          :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end

      it "is not available when the insight.secret_key is an empty string" do
        app.insight_app.secret_key=""

        lambda {
          get_via_rack "/__insight__/sql/explain", :query => "SELECT username FROM users",
          :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end
    end
  end
end
