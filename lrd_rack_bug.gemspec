# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{lrd_rack_bug}
  s.version = "0.3.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Evan Dorn", "Bryan Helmkamp"]
  s.date = %q{2011-05-02}
  s.email = %q{evan@lrdesign.com}
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
  s.summary = %q{Debugging toolbar for Rack applications implemented as middleware.  Rails 3
    compatible version maintained by Logical Reality Design.
  }
  s.description = %q{Debugging toolbar for Rack applications implemented as middleware.  Rails 3
    compatible version maintained by Logical Reality Design.
  }
  s.test_files = Dir.glob("spec/**/*")
end
