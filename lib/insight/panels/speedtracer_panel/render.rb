module Insight
  module SpeedTrace
    module Render
      include ::Insight::Render
      def compiled_source(filename)
        ::ERB.new(::File.read(::File.dirname(__FILE__) + "/../views/#{filename}.html.erb"), nil, "-").src
      end
    end
  end
end

