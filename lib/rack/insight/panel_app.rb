module Rack::Insight

  class PanelApp
    include Rack::Insight::Render

    attr_reader :request

    def call(env)
      @request = Rack::Request.new(env)
      dispatch
    end

    def render_template(*args)
      Rack::Response.new([super]).to_a
    end

    def params
      @request.GET
    end

    def not_found(message="")
      [404, {}, [message]]
    end

    def validate_params
      ParamsSignature.new(request).validate!
    end

  end

end
