module Rack::Insight
  class PanelsContent < PanelApp
    def initialize(insight_app)
      @insight_app = insight_app
      @request_table = Database::RequestTable.new
    end

    def dispatch
      return not_found("not get") unless @request.get?
      return not_found("id nil") if params['request_id'].nil?
      request = @request_table.select("*", "id = #{params['request_id']}").first
      return not_found("id not found") if request.nil?
      requests = @request_table.to_a.map do |row|
        { :id => row[0], :method => row[1], :path => row[2] }
      end
      render_template("request_fragment",
                      :request_id => params['request_id'].to_i,
                      :requests => requests,
                      :panels => @insight_app.panels)
    end
  end
end
