module Rack::Bug::SpeedTrace
  module Render
    include ::Rack::Bug::Render

    def compiled_source(filename)
      ::ERB.new(::File.read(::File.dirname(__FILE__) + "/../views/#{filename}.html.erb"), nil, "-").src
    end
  end
end
