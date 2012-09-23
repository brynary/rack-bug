# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/insight/version', __FILE__)

Gem::Specification.new do |s|
  s.name = %q{rack-insight}
  s.version = Rack::Insight::VERSION

  s.authors = ["Peter Boling", "Evan Dorn", "Judson Lester", "Bryan Helmkamp"]
  s.email = %w{peter.boling@gmail.com evan@lrdesign.com judson@lrdesign.com bryan@brynary.com}
  s.extra_rdoc_files = [
    "README.md",
    "LICENSE",
    "CHANGELOG"
  ]

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.homepage      = "https://github.com/pboling/rack-insight"
  s.summary = %q{Debugging toolbar for Rack applications implemented as
    middleware.}
  s.description = %q{Debugging toolbar for Rack applications implemented as
    middleware.  Based on logical-insight and rack-bug. }

  s.add_runtime_dependency("rack")
  s.add_runtime_dependency("uuidtools", ">= 2.1.2") # incurs far fewer dependencies that the uuid gem, and no shell forking
  s.add_runtime_dependency("sqlite3", ">= 1.3.3")
  s.add_development_dependency "redcarpet"
  s.add_development_dependency(%q<reek>, [">= 1.2.8"])
  s.add_development_dependency(%q<roodi>, [">= 2.1.0"])
  s.add_development_dependency(%q<rake>, [">= 0"])
  s.add_development_dependency "rspec", ">= 2.11.0"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "webrat"
  s.add_development_dependency "debugger"
end
