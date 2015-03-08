## 0.6 / 2015-03-08

  * Bug Fixes

    * Complete rewrite of `EnableButton` to ensure compatibility with all other Rack apps by Peter Boling
    * Removed duplicate config entry for `:verbosity` by Peter Boling

  * Other

    * Added Sinatra example to Readme by Peter Boling
    * spec improvements by Peter Boling
    * upgrade to latest version of Ruby for development by Peter Boling
    * Fixed Markdown syntax on CHANGELOG => CHANGELOG.md by Peter Boling
    * added bin scripts, but do not include in gem package by Peter Boling

## 0.5.30 / 2015-01-07

  * Bug Fixes

    * Removed dependence on rails by @javierhonduco

  * Other

    * Added working example: https://github.com/pboling/x-cascade_header_rails/tree/rails3


## 0.5.29 / 2014-11-06

  * Bug Fixes

    * Fixed bug with asset pipeline by @hck https://github.com/pboling/rack-insight/pull/28

    * Various bug fixes from @bibendi, @Napolskih, @abak-press, @semenyukdmitriy,

    * Fixed travis build by @michaelmior

    * Fixed serving of the toolbar by Peter Boling

    * All specs passing by Peter Boling

  * Other

    * Improved Readme by Peter Boling

## 0.5.28 / 2014-01-14

  * Bug Fixes

    * All specs passing by Peter Boling

  * Other

    * No reliance on rack's request.media_type by Peter Boling

    * Update README.md by Peter Boling

    * Add a Bitdeli badge to README by Bitdeli Chef

    * Quicker access to config by Peter Boling

    * Respond to requests with text/plain mime type by Peter Boling

    * Implement :handle_javascript option (default true) by Peter Boling

    * Remove dependency on git for gemspec by Peter Boling

    * Fix typo in example code by Peter Boling

    * Attributions by Peter Boling

    * Improved Readme by Peter Boling



## 0.5.27 / 2013-09-03

  * Other

    * Improved configuration of logging and verbosity by Peter Boling

      * Moved VERBOSITY from Logging module into Config class

    * gemspec email should reflect who the current contacts are for the gem by Peter Boling

    * Removed unused development dependencies by Peter Boling

    * All specs passing! by Peter Boling

    * Fixing deprecations by Peter Boling

    * Require the standard Ruby Logger by Peter Boling

    * Convert to .ruby-version by Peter Boling

    * Add license and platform to gemspec by Peter Boling

## 0.5.26 / 2013-08-06

  * Bug Fixes

    * Dont reload page, just close panel by Harry Walter

    * Allow panels to scroll when fixed to bottom by Harry Walter

    * Set position to fixed to keep toolbar at bottom by Harry Walter

  * Other

    * Update README.md by Agis Anastasopoulos

## 0.5.25 / 2013-03-15

  * Bug Fixes

    * active_record_panel is fixed! [(kjg - Kevin Glowacz)](https://github.com/kjg)

## 0.5.24 / 2013-01-01

  * Bug Fixes

    * (Issue #17) Fix 20x performance hit with default log level by changing default log level from `:debug` to `:silent` (Rack::Insight::Logging::VERBOSITY[:silent])

    * Changed event logging in the instrumentation from `:high` to `:debug` level.

## 0.5.23 / 2012-09-14

  * New Features

    * No longer rescue Object, and instead rescue Standard Error.
      If this is a problem strange non-StandardErrors should be wrapped. (pboling - Peter Boling)

    * Refactor Panel error handling. (pboling - Peter Boling)

      Create error handling method: `handle_error_for(method_name, exception)`
        Logs the error.
        Returns HTML for the view.
        Simplifies error handling in any panel that overrides one of:
          content, heading, content_for_request and heading_for_request
        like this:

          def content
            # Do stuff
          rescue StandardError => ex
            handle_error_for(method_name, ex)
          end

## 0.5.22 / 2012-09-14

  * New Features

    * Improve handling of decoding and marshalling problems with new config options and implementation: (pboling - Peter Boling)

          :database => a hash.  Keys :raise_encoding_errors, and :raise_decoding_errors are self explanatory
                   :raise_encoding_errors
                       When set to true, if there is an encoding error (unlikely)
                       it will cause a 500 error on your site.  !!!WARNING!!!
                   :raise_decoding_errors
                       The bundled panels should work fine with :raise_decoding_errors set to true or false
                       but custom panel implementations may prefer one over the other
                       The bundled panels will capture these errors and perform admirably.
                       Site won't go down unless a custom panel is not handling the errors well.

  * Bug Fixes

    * Fixes for redis panel. (oggy - George Ogata)

  * Other

    * Error system improvements and refactoring (pboling - Peter Boling)

    * Internal config validation system (pboling - Peter Boling)

## 0.5.21 / 2012-09-13

  * Attempting to handle values that get stored in the sqlite db, but which can't be re-marshalled, without failing the entire panel (pboling - Peter Boling)
  * Much nicer error handling output in panel heading and panel content areas (pboling - Peter Boling)

## 0.5.20 / 2012-09-13

  * Bug Fixes

    * Fix panel error handling (pboling - Peter Boling)

## 0.5.19 / 2012-09-13

  * Other

    * Extend panel error backtrace logging to include full backtrace (pboling - Peter Boling)
    * Improved table template for magical panels (pboling - Peter Boling)

  * Bug Fixes

    * Fix redis panel, maybe... (oggy - George Ogata)

## 0.5.18 / 2012-09-13

  * Bug Fixes

    * panel content is no longer covered by panel toolbar when positioned on bottom

  * Other

    * Fix Typo in templates panel

## 0.5.17 / 2012-09-13

  * New Features

    * MagicInsight!  WARNING: Magic is dangerous.  (pboling - Peter Boling)

      * MagicInsight is a new mixin that can be used by any 'stat' type class built for Rack::Bug / LogicalInsight / Rack::Insight.
        Just include Rack::Insight::MagicInsight in your stat class and then to render call:

            render_template 'magic_panel', :magic_insights => your_stat_object, :name => 'panel name'

        Read the source for Rack::Insight::MagicInsight and heed the warnings.
        MagicInsight is used internally by Rack::Insight for magic panels and the templates panel.

    * panel content now stays out of your page content, by displaying below it. (pboling - Peter Boling)

  * Bug Fixes

    * Fixed the hardly working TemplatesPanel (Issue 1) (pboling - Peter Boling)
    * Correct logging/debug statements (pboling - Peter Boling)
    * Better tracking of which panels are probing (pboling - Peter Boling)

  * Other

    * TemplatesPanel is now more aligned with the Rack::Insight Panel API. (pboling - Peter Boling)

## 0.5.16 / 2012-09-11

  * Other

    * Improved handling of no content for a panel. (pboling - Peter Boling)

## 0.5.14-15 / 2012-09-11

  * New Features

    * Panel level configurations for :probes are now supported by default on all panels (pboling - Peter Boling)
    * Auto-magical panel names (pboling - Peter Boling)
    * Auto-magical panel probe detection and storage (pboling - Peter Boling)
    * Auto-magical panel content (pboling - Peter Boling)
    * Auto-magical table creation (skipped with self.has_table = false in a Panel class definition) (pboling - Peter Boling)
    * Under construction, or blank, panels have more scaffolding (pboling - Peter Boling)

## 0.5.13 / 2012-09-10

  * Bug Fixes

    * Fixed the double logging of anything logged with ActiveSupport::BufferedLogger (via the new :panel_configs) (pboling - Peter Boling)

  * New Features

    * Panel level configuration options for all panels, including extension gems. (pboling - Peter Boling)
      Currently this is implemented in the log_panel, and configured as:
        Rack::Insight::Config.configure do |config|
          config[:panel_configs][:log_panel] = {:watch => {'Logger' => :add}}
        end
    * Count number of Log Entries (pboling - Peter Boling)

## 0.5.12 / 2012-09-10

  * Other

    * Improving documentation by Peter Boling

  * New Features

    * persistent toolbar position by Alif Rachmawadi

## 0.5.11 / 2012-09-05

  * Bug Fixes

    * Fixed Encoding::CompatibilityError by Michael Grosser

## 0.5.10 / 2012-09-04

  * Bug Fixes

    * Ajax requests for previously cached panel data now go to root (/), which allows it to work on non-root URLs. (pboling - Peter Boling)

## 0.5.9 / 2012-09-04

  * New Features

    * FilteredBacktrace was disabled in LogicalInsight.  It's now back.  It is now configurable via the configure block. (pboling - Peter Boling)

## 0.5.8 / 2012-09-04

  * Bug Fixes

    * working template_root for rack-insight extension libraries (pboling - Peter Boling)

## 0.5.7 / 2012-09-03

  * Bug Fixes

    * require 'logger' important when using Ruby Logger (pboling - Peter Boling)

## 0.5.6 / 2012-08-31

  * Other

    * Wrap debug logging in verbose check (pboling - Peter Boling)
    * Documentation (pboling - Peter Boling)

## 0.5.5 / 2012-08-31

  * New Features

    * Extension gems now automatically look for their view templates
      relative to the panel class file that tries to render them. (pboling - Peter Boling)
    * Two levels of log verbosity filtering to allow re-use of the Rails log, but to not force same level output from
      rack-insight as the rails log is set to for the env.  It will never be more logging than Rails log's env level,
      but it can, and usually should, be less. (pboling - Peter Boling)

  * Fixed a number of bugs, and refactored some things.  Please let me know if you use it/break it! (pboling - Peter Boling)

## 0.5.0 / 2012-08-29 - transition to rack_insight

  * Compatibility

    * Restructure gem so Insight is inside a namespace, because I have classes named Insight that are obscured by
      logical_insight gem when loaded.  Logical also seemed like it may be a class name somewhere, hence going back to
      the Rack namespace a la rack-bug.  Keeping the (now nested) Insight namespace as well, because - genetics. (pboling - Peter Boling)

  * Other

    * Fix spelling of retreive => retrieve (pboling - Peter Boling)
    * Remove redundant time method from cache_panel/stats.rb (pboling - Peter Boling)

## 0.4.X - last of logical_insight

  * New features

    * Can use LoggerPanel on ruby stdlib Logger in non-rails app (Tim Connor)

  * Bug fixes

    * Fix profile, explain and select in the queries tab, fixes issue #22 (ebertech)

  * Minor fixes

    * Explicitly require 'digest/sha1' (Jérémy Lecour)
    * Eliminate unreachable code in params signature validation (Tim Connor)

  * Compatibilty

    * Make Redis panel compatible with latest redis-rb gem, without breaking older redis-rb versions (Luke Melia)

  * Other

    * Refactoring and code cleanup (Tim Connor)
    * Testing cleanup - better isolation of Rails vs. non-Rails in tests (Tim Connor)

## 0.3.0 / 2010-05-28

  * New features

    * Log panel includes log level and timestamp (Tim Connor)
    * Sphinx panel (George Chatzigeorgiou)
    * Backtraces for Redis panel (Luke Melia & Joey Aghion)

  * Minor fixes

    * Don't "enable" rack bug if you hit cancel on the bookmarklet prompt (Mischa Fierer)

  * Compatibilty

    * backtrace filtering now supports more than just Rails (Alex Chaffee)
    * compatibility with current rack-test (Luke Melia & Joey Aghion)
    * update Sinatra sample app (Tim Conner)

## 0.2.1

  * The beginning of recorded history
