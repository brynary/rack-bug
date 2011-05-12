# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{lrd_rack_bug}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bryan Helmkamp", "Evan Dorn", "Judson Lester"]
  s.date = %q{2011-05-02}
  s.email = %q{evan@lrdesign.com judson@lrdesign.com}
  s.extra_rdoc_files = [
    "README.md",
    "MIT-LICENSE.txt"
  ]
  s.files = [
    ".gitignore",
    "History.txt",
    "MIT-LICENSE.txt",
    "README.md",
    "Rakefile",
    "Thorfile",
    "lrd_rack_bug.gemspec"
  ]
  s.files += Dir.glob("lib/**/*")
  s.files += Dir.glob("spec/**/*")

  s.homepage = %q{http://github.com/lrdesign/lrd_rack_bug}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Debugging toolbar for Rack applications implemented as 
    middleware.  Rails 3 compatible version maintained by Logical Reality 
    Design.  }
  s.description = %q{Debugging toolbar for Rack applications implemented as 
    middleware.  Rails 3 compatible version maintained by Logical Reality 
    Design.  }
  s.add_dependency("uuid", "~> 2.3.1")
  #s.test_files = Dir.glob("spec/**/*") gem test assumes Test::Unit
end
