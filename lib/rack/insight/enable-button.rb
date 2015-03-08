module Rack::Insight
  class EnableButton < Struct.new :app, :insight
    include Render

    CONTENT_TYPE_REGEX = /text\/(html|plain)|application\/xhtml\+xml/

    def call(env)
      status, headers, response = app.call(env)

      if okay_to_modify?(env, headers)
        body = response.inject("") do |memo, part|
          memo << part
          memo
        end
        index = body.rindex("</body>")
        if index
          body.insert(index, render)
          headers["Content-Length"] = body.bytesize.to_s
          response = [body]
        end
      end

      [status, headers, response]
    end

    def okay_to_modify?(env, headers)
      return false unless headers["Content-Type"] =~ CONTENT_TYPE_REGEX
      return !match_path_filters?(env["rack-insight.path_filters"], env["REQUEST_PATH"])
    end

    def match_path_filters?(path_filters, path)
      to_regex(path_filters).find { |filter| path =~ filter }
    end

    def to_regex(filters)
      (filters || []).map { |str| %r(^#{str}) }
    end

    def render
      render_template("enable-button")
    end
  end
end
