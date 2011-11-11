
def compiled_source(filename)
  ::ERB.new(::File.read(::File.dirname(__FILE__) + "/../views/#{filename}.html.erb"), nil, "-").src
end
end
