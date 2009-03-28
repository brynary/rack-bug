require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Rack::Bug
  describe SQLPanel do
    before do
      SQLPanel.reset
      header "rack-bug.panel_classes", [SQLPanel]
    end
    
    describe "heading" do
      it "displays the total SQL query count" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_heading("1 Queries")
      end
      
      it "displays the total SQL time" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_heading(/Queries \(\d+\.\d{2}ms\)/)
      end
    end
    
    describe "content" do
      it "displays each executed SQL query" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_row("#sql", "SELECT NOW();")
      end
      
      it "displays the time of each executed SQL query" do
        SQLPanel.record("SELECT NOW();") { }
        response = get "/"
        response.should have_row("#sql", "SELECT NOW();", TIME_MS_REGEXP)
      end
    end
    
    def stub_result(results = [[]])
      columns = results.first
      fields = columns.map { |c| stub("field", :name => c) }
      rows = results[1..-1]
      
      result = stub("result", :fetch_fields => fields)
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
        header "rack-bug.secret_key", "abc"
        expect_query "SELECT username FROM users",
          [["username"],
           ["bryan"]]
        
        response = get "/__rack_bug__/execute_sql", :query => "SELECT username FROM users",
          :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        response.should contain("SELECT username FROM users")
        response.should be_ok
      end
      
      it "is forbidden when the hash is missing or wrong" do
        header "rack-bug.secret_key", 'abc'
        
        lambda {
          get "/__rack_bug__/execute_sql", :query => "SELECT username FROM users",
            :hash => "foobar"
        }.should raise_error(SecurityError)
      end
      
      it "is not available when the rack-bug.secret_key is nil" do
        header "rack-bug.secret_key", nil
        
        lambda {
          get "/__rack_bug__/execute_sql", :query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end
      
      it "is not available when the rack-bug.secret_key is an empty string" do
        header "rack-bug.secret_key", ""
        
        lambda {
          get "/__rack_bug__/execute_sql", :query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end
    end
    
    describe "explain_sql" do
      it "displays the query explain plan" do
        header "rack-bug.secret_key", "abc"
        expect_query "EXPLAIN SELECT username FROM users",
          [["table"],
           ["users"]]
        
        response = get "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
          :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        response.should contain("SELECT username FROM users")
        response.should be_ok
      end
      
      it "is forbidden when the hash is missing or wrong" do
        header "rack-bug.secret_key", 'abc'
        
        lambda {
          get "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
            :hash => "foobar"
        }.should raise_error(SecurityError)
      end
      
      it "is not available when the rack-bug.secret_key is nil" do
        header "rack-bug.secret_key", nil
        
        lambda {
          get "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end
      
      it "is not available when the rack-bug.secret_key is an empty string" do
        header "rack-bug.secret_key", ""
        
        lambda {
          get "/__rack_bug__/explain_sql", :query => "SELECT username FROM users",
            :hash => "6f286f55b75716e5c91f16d77d09fa73b353ebc1"
        }.should raise_error(SecurityError)
      end
    end
  end
end