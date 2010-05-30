Rack::Bug
=========

* Repository: [http://github.com/brynary/rack-bug](http://github.com/brynary/rack-bug)

Description
-----------

Rack::Bug adds a diagnostics toolbar to Rack apps. When enabled, it injects a floating div
allowing exploration of logging, database queries, template rendering times, etc.

Features
--------

* Password-based security
* IP-based security
* Rack::Bug instrumentation/reporting is broken up into panels.
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
        * Sphinx
    * The API for adding your own panels is simple and powerful

Rails quick start
---------------------------

    script/plugin install git://github.com/brynary/rack-bug.git

In config/environments/development.rb, add:

    config.middleware.use "Rack::Bug",
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring"

Add the bookmarklet to your browser:

    open http://RAILS_APP/__rack_bug__/bookmarklet.html

Using with non-Rails Rack apps
------------------------------
Nothing should prevent this from being possible. Please contribute docs if you do this. :-)

Configuring custom panels
-------------------------

Specify the set of panels you want, in the order you want them to appear:

    require "rack/bug"

    ActionController::Dispatcher.middleware.use Rack::Bug,
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring",
      :panel_classes => [
        Rack::Bug::TimerPanel,
        Rack::Bug::RequestVariablesPanel,
        Rack::Bug::RedisPanel,
        Rack::Bug::TemplatesPanel,
        Rack::Bug::LogPanel,
        Rack::Bug::MemoryPanel
      ]


Running Rack::Bug in staging or production
------------------------------------------

We have have found that Rack::Bug is fast enough to run in production for specific troubleshooting efforts.

### Configuration ####

Add the middleware configuration to an initializer or the appropriate environment files, taking the rest of this section into consideration.

### Security ####

Restrict access to particular IP addresses:

    require "ipaddr"

    ActionController::Dispatcher.middleware.use "Rack::Bug"
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring",
      :ip_masks   => [IPAddr.new("2.2.2.2/0")]

Restrict access using a password:

    ActionController::Dispatcher.middleware.use "Rack::Bug",
      :secret_key => "someverylongandveryhardtoguesspreferablyrandomstring",
      :password   => "yourpassword"


Authors
-------

- Maintained by [Bryan Helmkamp](mailto:bryan@brynary.com)
- Contributions from Luke Melia, Joey Aghion, Tim Connor, and more

Thanks
------
Inspiration for Rack::Bug is primarily from the Django debug toolbar. Additional ideas from Rails footnotes, Rack's ShowException middleware, Oink, and Rack::Cache

Thanks to Weplay.com for supporting the development of Rack::Bug

Development
-----------
For development, you'll need to install the following gems: rspec, rack-test, webrat, sinatra

License
-------

See MIT-LICENSE.txt in this directory.
