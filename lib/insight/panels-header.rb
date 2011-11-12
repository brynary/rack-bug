module Insight
  def initialize(bug_app)
    @bug_app = bug_app
    @request_table = Database::RequestTable.new
  end

  def dispatch
    return not_found("not get") unless @request.get?
    return not_found("id nil") if params['request_id'].nil?
    request = @request_table.select("*", "id = #{params['request_id']}").first
    return not_found("id not found") if request.nil?
    render_template("headers_fragment",
                    :request_id => params['request_id'].to_i,
                    :panels => @bug_app.panels)
  end
end
