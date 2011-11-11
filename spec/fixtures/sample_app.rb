require "sinatra/base"
require 'logger'

RAILS_ENV = "development" unless defined?(RAILS_ENV)
log_to = RAILS_ENV == "test" ? StringIO.new : STDOUT
LOGGER = Logger.new(log_to)

class SampleApp < Sinatra::Base
  use Insight#, :intercept_redirects => true, :password => 'secret'
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
          <p><a href="__insight__/bookmarklet.html">Page with bookmarklet for enabling Insight</a></p>
          <p><a href="/error">Page with an error to check insight not rescuing errors</a></p>
        </body>
      </html>
    HTML
  end

end
