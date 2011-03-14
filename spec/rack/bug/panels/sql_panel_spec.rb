require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

class Rack::Bug
  describe SQLPanel do
    before do
      SQLPanel.reset
      rack_env "rack-bug.panel_classes", [SQLPanel]

      unless defined?(ActiveRecord)
        @added_rails = true
        Object.const_set :ActiveRecord, Module.new
        ActiveRecord.const_set :Base, Class.new
      end
    end
    
    after do
      Object.send :remove_const, :ActiveRecord if @added_active_record
    end

    describe "heading" do
      it "displays the total SQL query count" do
        SQLPanel.record("SELECT NOW();") { }
        response = get_via_rack "/"
        response.should have_heading("1 Queries")
      end

      it "displays the total SQL time" do
        SQLPanel.record("SELECT NOW();") { }
        response = get_via_rack "/"
        response.should have_heading(/Queries \(\d+\.\d{2}ms\)/)
      end
    end

    describe "content" do
      it "displays each executed SQL query" do
        SQLPanel.record("SELECT NOW();") { }
        response = get_via_rack "/"
        response.should have_row("#sql", "SELECT NOW();")
      end

      it "displays the time of each executed SQL query" do
        SQLPanel.record("SELECT NOW();") { }
        response = get_via_rack "/"
        response.should have_row("#sql", "SELECT NOW();", TIME_MS_REGEXP)
      end
    end

    def stub_result(results = [[]])
      columns = results.first
      rows = results[1..-1]

      result = stub("result", :fields => columns)
      result.stub!(:each).and_yield(*rows)
      return result
    end

    def expect_query(sql, results)
      conn = stub("connection")
      ActiveRecord::Base.stub!(:connection => conn)
      conn.should_receive(:execute).with(sql).and_return(stub_result(results))
    end

    describe "execute_sql" do
      it "displays the query results" do
        rack_env "rack-bug.secret_key", "abc"
        expect_query "SELECT username FROM users",
          [["username"],
           ["bryan"]]

        response = get_via_rack "/__rack_bug__/execute_sql", {:query => "SELECT username FROM users",
          :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"}, {:xhr => true}
        response.should contain("SELECT username FROM users")
        response.should be_ok
      end

      it "is forbidden when the hash is missing or wrong" do
        rack_env "rack-bug.secret_key", 'abc'

        lambda {
          get_via_rack "/__rack_bug__/execute_sql", {:query => "SELECT username FROM users",
            :hash => "foobar"}, {:xhr => true}
        }.should raise_error(SecurityError)
      end

      it "is not available when the rack-bug.secret_key is nil" do
        rack_env "rack-bug.secret_key", nil

        lambda {
          get_via_rack "/__rack_bug__/execute_sql", {:query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"}, {:xhr => true}
        }.should raise_error(SecurityError)
      end

      it "is not available when the rack-bug.secret_key is an empty string" do
        rack_env "rack-bug.secret_key", ""

        lambda {
          get_via_rack "/__rack_bug__/execute_sql", {:query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"}, {:xhr => true}
        }.should raise_error(SecurityError)
      end
    end

    describe "explain_sql" do
      it "displays the query explain plan" do
        rack_env "rack-bug.secret_key", "abc"
        expect_query "EXPLAIN SELECT username FROM users",
          [["table"],
           ["users"]]

        response = get_via_rack "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
          :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        response.should contain("SELECT username FROM users")
        response.should be_ok
      end

      it "is forbidden when the hash is missing or wrong" do
        rack_env "rack-bug.secret_key", 'abc'

        lambda {
          get_via_rack "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
            :hash => "foobar"
        }.should raise_error(SecurityError)
      end

      it "is not available when the rack-bug.secret_key is nil" do
        rack_env "rack-bug.secret_key", nil

        lambda {
          get_via_rack "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end

      it "is not available when the rack-bug.secret_key is an empty string" do
        rack_env "rack-bug.secret_key", ""

        lambda {
          get_via_rack "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end
    end
  end
end
