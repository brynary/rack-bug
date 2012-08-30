$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'
require "sinatra/base"
require 'logger'

RAILS_ENV = "development" unless defined?(RAILS_ENV)
log_to = RAILS_ENV == "test" ? StringIO.new : STDOUT
LOGGER = Logger.new(log_to)

class SampleApp < Sinatra::Base
  class OneLastThing
    def initialize(app)
      @app = app
    end

    def call(env)
      st,hd,bd = @app.call(env)
      unless SampleApp.before_returning.nil?
        SampleApp.before_returning.call
        SampleApp.before_returning = nil
      end
      return st,hd,bd
    end
  end

  class << self
    attr_accessor :insight_app
    attr_accessor :before_returning
    def before_return(&block)
      self.before_returning = block
    end
  end



  use Rack::Insight::App, :log_path => "rack-insight-test.log", :on_initialize => proc {|app|
    self.insight_app = app
  }
  use OneLastThing

  set :environment, 'test'

  configure :test do
    set :raise_errors, true
  end

  get "/redirect" do
    redirect "/"
  end

  get "/error" do
    raise "Error!"
  end

  get "/" do
    if params[:content_type]
      headers["Content-Type"] = params[:content_type]
    end
    LOGGER.error "I am a log message"
    <<-HTML
      <html>
        <head>
        </head>
        <body>
          <p>Hello</p>
          <p><a href="__insight__/bookmarklet.html">Page with bookmarklet for enabling Rack::Insight</a></p>
          <p><a href="/error">Page with an error to check insight not rescuing errors</a></p>
        </body>
      </html>
    HTML
  end

end
