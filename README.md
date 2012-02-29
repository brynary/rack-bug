Insight
=========

Insight began life as an LRDesign fork of Rack::Bug by brynary.  We started a fork because, at the time, the main project wasn't making progress on Rails 3 support.  Since then we've rewritten a lot of the code to make it more modular, easier to extend, and to store information about multiple requests so you can use it to inspect your AJAX requests (or any past request), not just previous page loads.

Having made really significant architectural changes, we'll be keeping Insight a separate project for the forseeable future.

* Forked From: [http://github.com/brynary/rack-bug](http://github.com/brynary/rack-bug)

Description
-----------

Insight adds a diagnostics toolbar to Rack apps. When enabled, it injects a floating div
allowing exploration of logging, database queries, template rendering times, etc.   Insight
stores debugging info over many requests, incuding AJAX requests.

Features
--------

* Password-based security
* IP-based security
* Insight instrumentation/reporting is broken up into panels.
    * Panels in default configuration:
        * Rails Info
        * Timer
        * Request Variables
        * SQL
        * Active Record
        * Cache
        * Templates
        * Log
        * Memory
    * Other bundled panels:
        * Redis
        * Speedtracer
    * Retired panels - if needed they could come back quickly:
        * Sphinx
        * Mongo
    * The API for adding your own panels is simple and very powerful
        * Consistent interface to instrument application code
        * Consistent timing across panels
        * Easy to add sub-applications for more detailed reports (c.f. SQLPanel)
        * The documentation is scarce, so there's a feeling of adventure :/

Rails quick start
---------------------------

Add this to your Gemfile
    gem "logical-insight"

In config/environments/development.rb, add:

    config.middleware.use "Insight::App",
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring"

Any environment with Insight loaded will have a link to "Insight" added to as the last child of BODY to normal responses.  Clicking that link will load the toolbar.  It's set with an id of "logical-insight-enabler", so it can be styled to go somewhere more noticeable.  E.g. "position: absolute; top: 0; left: 0"

Using with non-Rails Rack apps
------------------------------

Just 'use Insight' as any other middleware.  See the SampleApp in the spec/fixtures folder for an example Sinatra app.

If you wish to use the logger panel define the LOGGER constant that is a ruby Logger or ActiveSupport::BufferedLogger

Configuring custom panels
-------------------------

Specify the set of panels you want, in the order you want them to appear:

    require "logical-insight"

    ActionController::Dispatcher.middleware.use "Insight::App",
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring",
      :panel_files => %w[
        timer_panel
        request_variables_panel
        redis_panel
        templates_panel
        log_panel
        memory_panel
      ]

Files are looked up by prepending "insight/panels/" and requiring them.  Subclasses of Insight::Panel are loaded and added to the toolbar.  This makes it easier to work with the configuration and extend Insight with plugin gems.

Running Insight in staging or production
------------------------------------------

We have have found that Insight is fast enough to run in production for specific troubleshooting efforts.

### Configuration ####

Add the middleware configuration to an initializer or the appropriate environment files, taking the rest of this section into consideration.

### Security ####

Restrict access to particular IP addresses:

    require "ipaddr"

    ActionController::Dispatcher.middleware.use "Insight::App"
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring",
      :ip_masks   => [IPAddr.new("2.2.2.2/0")]

Restrict access using a password:

    ActionController::Dispatcher.middleware.use "Insight::App",
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring",
      :password   => "yourpassword"

#### custom file path for the logging database ####

Logical Insight uses SQLite to store data from requests, and outputs a database file in the root directory. If you need the file to be created at another location (i.e. Heroku), you can pass a custom file path.

    ActionController::Dispatcher.middleware.use "Insight::App"
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring",
      :database_path => "tmp/my_insight_db.sqlite"

Authors
-------

- Maintained by [Judson Lester](mailto:judson@lrdesign.com)
- Contributions from Luke Melia, Joey Aghion, Tim Connor, and more
- Based on Rack::Bug by Bryan Helmkamp

Thanks
------
Insight owes a lot to Rack::Bug, as the basis project.  There's a lot of smart in there.  Many thanks to Bryan for building it.

Inspiration for Rack::Bug is primarily from the Django debug toolbar. Additional ideas from Rails footnotes, Rack's ShowException middleware, Oink, and Rack::Cache

Development
-----------
For development, you'll need to install the following gems: rspec, rack-test, webrat, sinatra

License
-------

See MIT-LICENSE.txt in this directory.
