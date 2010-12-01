# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rack-bug}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bryan Helmkamp"]
  s.date = %q{2010-09-03}
  s.email = %q{bryan@brynary.com}
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
    "lib/rack/bug.rb",
    "lib/rack/bug/autoloading.rb",
    "lib/rack/bug/filtered_backtrace.rb",
    "lib/rack/bug/options.rb",
    "lib/rack/bug/panel.rb",
    "lib/rack/bug/panel_app.rb",
    "lib/rack/bug/panels/active_record_panel.rb",
    "lib/rack/bug/panels/active_record_panel/activerecord_extensions.rb",
    "lib/rack/bug/panels/cache_panel.rb",
    "lib/rack/bug/panels/cache_panel/dalli_extension.rb",
    "lib/rack/bug/panels/cache_panel/memcache_extension.rb",
    "lib/rack/bug/panels/cache_panel/panel_app.rb",
    "lib/rack/bug/panels/cache_panel/stats.rb",
    "lib/rack/bug/panels/log_panel.rb",
    "lib/rack/bug/panels/log_panel/logger_extension.rb",
    "lib/rack/bug/panels/memory_panel.rb",
    "lib/rack/bug/panels/rails_info_panel.rb",
    "lib/rack/bug/panels/redis_panel.rb",
    "lib/rack/bug/panels/redis_panel/redis_extension.rb",
    "lib/rack/bug/panels/redis_panel/stats.rb",
    "lib/rack/bug/panels/request_variables_panel.rb",
    "lib/rack/bug/panels/sphinx_panel.rb",
    "lib/rack/bug/panels/sphinx_panel/sphinx_extension.rb",
    "lib/rack/bug/panels/sphinx_panel/stats.rb",
    "lib/rack/bug/panels/sql_panel.rb",
    "lib/rack/bug/panels/sql_panel/panel_app.rb",
    "lib/rack/bug/panels/sql_panel/query.rb",
    "lib/rack/bug/panels/sql_panel/sql_extension.rb",
    "lib/rack/bug/panels/templates_panel.rb",
    "lib/rack/bug/panels/templates_panel/actionview_extension.rb",
    "lib/rack/bug/panels/templates_panel/rendering.rb",
    "lib/rack/bug/panels/templates_panel/trace.rb",
    "lib/rack/bug/panels/timer_panel.rb",
    "lib/rack/bug/params_signature.rb",
    "lib/rack/bug/public/__rack_bug__/bookmarklet.html",
    "lib/rack/bug/public/__rack_bug__/bookmarklet.js",
    "lib/rack/bug/public/__rack_bug__/bug.css",
    "lib/rack/bug/public/__rack_bug__/bug.js",
    "lib/rack/bug/public/__rack_bug__/jquery-1.3.2.js",
    "lib/rack/bug/public/__rack_bug__/jquery.tablesorter.min.js",
    "lib/rack/bug/public/__rack_bug__/spinner.gif",
    "lib/rack/bug/rack_static_bug_avoider.rb",
    "lib/rack/bug/redirect_interceptor.rb",
    "lib/rack/bug/render.rb",
    "lib/rack/bug/toolbar.rb",
    "lib/rack/bug/views/error.html.erb",
    "lib/rack/bug/views/panels/active_record.html.erb",
    "lib/rack/bug/views/panels/cache.html.erb",
    "lib/rack/bug/views/panels/execute_sql.html.erb",
    "lib/rack/bug/views/panels/explain_sql.html.erb",
    "lib/rack/bug/views/panels/log.html.erb",
    "lib/rack/bug/views/panels/profile_sql.html.erb",
    "lib/rack/bug/views/panels/rails_info.html.erb",
    "lib/rack/bug/views/panels/redis.html.erb",
    "lib/rack/bug/views/panels/request_variables.html.erb",
    "lib/rack/bug/views/panels/sphinx.html.erb",
    "lib/rack/bug/views/panels/sql.html.erb",
    "lib/rack/bug/views/panels/templates.html.erb",
    "lib/rack/bug/views/panels/timer.html.erb",
    "lib/rack/bug/views/panels/view_cache.html.erb",
    "lib/rack/bug/views/redirect.html.erb",
    "lib/rack/bug/views/toolbar.html.erb",
    "rack-bug.gemspec",
    "spec/fixtures/config.ru",
    "spec/fixtures/dummy_panel.rb",
    "spec/fixtures/sample_app.rb",
    "spec/rack/bug/panels/active_record_panel_spec.rb",
    "spec/rack/bug/panels/cache_panel_spec.rb",
    "spec/rack/bug/panels/log_panel_spec.rb",
    "spec/rack/bug/panels/memory_panel_spec.rb",
    "spec/rack/bug/panels/rails_info_panel_spec.rb",
    "spec/rack/bug/panels/redis_panel_spec.rb",
    "spec/rack/bug/panels/sql_panel_spec.rb",
    "spec/rack/bug/panels/templates_panel_spec.rb",
    "spec/rack/bug/panels/timer_panel_spec.rb",
    "spec/rack/bug_spec.rb",
    "spec/rcov.opts",
    "spec/spec.opts",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/brynary/rack-bug}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rack-bug}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Debugging toolbar for Rack applications implemented as middleware}
  s.test_files = [
    "spec/fixtures/dummy_panel.rb",
    "spec/fixtures/sample_app.rb",
    "spec/rack/bug/panels/active_record_panel_spec.rb",
    "spec/rack/bug/panels/cache_panel_spec.rb",
    "spec/rack/bug/panels/log_panel_spec.rb",
    "spec/rack/bug/panels/memory_panel_spec.rb",
    "spec/rack/bug/panels/rails_info_panel_spec.rb",
    "spec/rack/bug/panels/redis_panel_spec.rb",
    "spec/rack/bug/panels/sql_panel_spec.rb",
    "spec/rack/bug/panels/templates_panel_spec.rb",
    "spec/rack/bug/panels/timer_panel_spec.rb",
    "spec/rack/bug_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 1.0"])
      s.add_development_dependency(%q<webrat>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<sinatra>, [">= 0"])
      s.add_development_dependency(%q<git>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 1.0"])
      s.add_dependency(%q<webrat>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<sinatra>, [">= 0"])
      s.add_dependency(%q<git>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 1.0"])
    s.add_dependency(%q<webrat>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<sinatra>, [">= 0"])
    s.add_dependency(%q<git>, [">= 0"])
  end
end
