# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/insight/version', __FILE__)

Gem::Specification.new do |s|
  s.name = %q{rack-insight}
  s.version = Rack::Insight::VERSION

  s.authors = ["Peter Boling", "Evan Dorn", "Judson Lester", "Bryan Helmkamp"]
  s.email = %w{peter.boling@gmail.com}
  s.extra_rdoc_files = [
    "README.md",
    "LICENSE",
    "CHANGELOG"
  ]

  s.files         = Dir.glob("{bin,lib,vendor}/**/*") + %w(LICENSE README.md CHANGELOG Rakefile)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  s.require_paths = ["lib"]

  s.licenses = ["MIT"]
  s.platform = Gem::Platform::RUBY

  s.homepage      = "https://github.com/pboling/rack-insight"
  s.summary = %q{Debugging toolbar for Rack applications implemented as middleware.}
  s.description = %q{Debugging toolbar for Rack applications implemented as middleware.
    Based on logical-insight and rack-bug. }

  s.add_runtime_dependency("rack")
  s.add_runtime_dependency("uuidtools", ">= 2.1.2") # incurs far fewer dependencies that the uuid gem, and no shell forking
  s.add_runtime_dependency("sqlite3", ">= 1.3.3")
  #s.add_development_dependency "redcarpet", ">= 3.0.0"
  s.add_development_dependency(%q<reek>, [">= 1.2.13"])
  #s.add_development_dependency(%q<executable-hooks>, [">= 1.3.1"])
  s.add_development_dependency(%q<roodi>, [">= 2.2.0"])
  s.add_development_dependency(%q<rake>, [">= 10.1.0"])
  s.add_development_dependency "rspec", "~> 2.14.1"
  s.add_development_dependency "sinatra", ">= 1.4.3"
  s.add_development_dependency "webrat", ">= 0.7.3"
  #s.add_development_dependency "debugger", ">= 1.6.1"
  s.add_development_dependency "nokogiri", "1.6.3.1"
end
