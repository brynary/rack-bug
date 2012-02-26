# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{logical-insight}
  s.version = "0.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bryan Helmkamp", "Evan Dorn", "Judson Lester"]
  s.date = %q{2011-12-13}
  s.email = %q{evan@lrdesign.com judson@lrdesign.com}
  s.extra_rdoc_files = [
    "README.md",
    "MIT-LICENSE.txt"
  ]
  s.homepage = %q{https://github.com/LRDesign/logical-insight}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Debugging toolbar for Rack applications implemented as
    middleware.  Rails 3 compatible version maintained by Logical Reality
    Design.  }
  s.description = %q{Debugging toolbar for Rack applications implemented as
    middleware.  Rails 3 compatible version maintained by Logical Reality
    Design.  }

    # Do this: y$@"
    # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
    #
  s.files = %w[
    lib/logical-insight.rb
    lib/insight.rb
    lib/insight/rack_static_bug_avoider.rb
    lib/insight/toolbar.rb
    lib/insight/views/request_fragment.html.erb
    lib/insight/views/enable-button.html.erb
    lib/insight/views/redirect.html.erb
    lib/insight/views/headers_fragment.html.erb
    lib/insight/views/panels/rails_info.html.erb
    lib/insight/views/panels/execute_sql.html.erb
    lib/insight/views/panels/timer.html.erb
    lib/insight/views/panels/view_cache.html.erb
    lib/insight/views/panels/speedtracer/serverevent.html.erb
    lib/insight/views/panels/speedtracer/traces.html.erb
    lib/insight/views/panels/speedtracer/servertrace.html.erb
    lib/insight/views/panels/sql.html.erb
    lib/insight/views/panels/templates.html.erb
    lib/insight/views/panels/explain_sql.html.erb
    lib/insight/views/panels/log.html.erb
    lib/insight/views/panels/active_record.html.erb
    lib/insight/views/panels/cache.html.erb
    lib/insight/views/panels/request_variables.html.erb
    lib/insight/views/panels/profile_sql.html.erb
    lib/insight/views/panels/redis.html.erb
    lib/insight/views/toolbar.html.erb
    lib/insight/views/error.html.erb
    lib/insight/options.rb
    lib/insight/panel.rb
    lib/insight/logger.rb
    lib/insight/database.rb
    lib/insight/panels-header.rb
    lib/insight/filtered_backtrace.rb
    lib/insight/panels-content.rb
    lib/insight/enable-button.rb
    lib/insight/instrumentation.rb
    lib/insight/app.rb
    lib/insight/panels/request_variables_panel.rb
    lib/insight/panels/redis_panel.rb
    lib/insight/panels/rails_info_panel.rb
    lib/insight/panels/sql_panel/panel_app.rb
    lib/insight/panels/sql_panel/query.rb
    lib/insight/panels/cache_panel/panel_app.rb
    lib/insight/panels/cache_panel/stats.rb
    lib/insight/panels/timer_panel.rb
    lib/insight/panels/redis_panel/redis_extension.rb
    lib/insight/panels/redis_panel/stats.rb
    lib/insight/panels/sql_panel.rb
    lib/insight/panels/templates_panel.rb
    lib/insight/panels/log_panel.rb
    lib/insight/panels/speedtracer_panel/trace-app.rb
    lib/insight/panels/speedtracer_panel/tracer.rb
    lib/insight/panels/active_record_panel.rb
    lib/insight/panels/cache_panel.rb
    lib/insight/panels/speedtracer_panel.rb
    lib/insight/panels/templates_panel/rendering.rb
    lib/insight/panels/memory_panel.rb
    lib/insight/request-recorder.rb
    lib/insight/public/__insight__/bookmarklet.html
    lib/insight/public/__insight__/bookmarklet.js
    lib/insight/public/__insight__/spinner.gif
    lib/insight/public/__insight__/insight.css
    lib/insight/public/__insight__/jquery.tablesorter.min.js
    lib/insight/public/__insight__/insight.js
    lib/insight/public/__insight__/jquery-1.3.2.js
    lib/insight/redirect_interceptor.rb
    lib/insight/panel_app.rb
    lib/insight/instrumentation/instrument.rb
    lib/insight/instrumentation/package-definition.rb
    lib/insight/instrumentation/backstage.rb
    lib/insight/instrumentation/client.rb
    lib/insight/instrumentation/setup.rb
    lib/insight/instrumentation/probe.rb
    lib/insight/instrumentation/probe-definition.rb
    lib/insight/params_signature.rb
    lib/insight/render.rb
    spec/custom_matchers.rb
    spec/spec_helper.rb
    spec/instrumentation_spec.rb
    spec/fixtures/config.ru
    spec/fixtures/dummy_panel.rb
    spec/fixtures/sample_app.rb
    spec/spec.opts
    spec/insight_spec.rb
    spec/insight/panels/mongo_panel_spec_pending.rb
    spec/insight/panels/active_record_panel_spec.rb
    spec/insight/panels/redis_panel_spec.rb
    spec/insight/panels/templates_panel_spec.rb
    spec/insight/panels/memory_panel_spec.rb
    spec/insight/panels/timer_panel_spec.rb
    spec/insight/panels/sql_panel_spec.rb
    spec/insight/panels/rails_info_panel_spec.rb
    spec/insight/panels/log_panel_spec.rb
    spec/insight/panels/cache_panel_spec.rb
    spec/rcov.opts
    History.txt
    MIT-LICENSE.txt
    README.md
    Rakefile
    Thorfile
  ]

  s.add_development_dependency "corundum", "~> 0.0.1"

=begin
Legacy files: would like to re-include them, but they need work
    lib/insight/views/panels/mongo.html.erb
    lib/insight/panels/mongo_panel/mongo_extension.rb
    lib/insight/panels/mongo_panel/stats.rb
    lib/insight/panels/mongo_panel.rb

    lib/insight/views/panels/sphinx.html.erb
    lib/insight/panels/sphinx_panel/stats.rb
    lib/insight/panels/sphinx_panel.rb

    This one is mostly just a curiousity
    lib/insight/panels/speedtracer_panel/profiling.rb
=end

  s.add_dependency("uuid", "~> 2.3.1")
  s.add_dependency("sqlite3", "~> 1.3.3")
  #s.test_files = Dir.glob("spec/**/*") gem test assumes Test::Unit
end
