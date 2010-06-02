$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'
require "rack/bug"

require "sinatra/base"

class SampleApp < Sinatra::Base
  use Rack::Bug
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

    <<-HTML
      <html>
        <head>
        </head>
        <body>
          <p>Hello</p>
          <p><a href="__rack_bug__/bookmarklet.html">Page with bookmarklet for enabling Rack::Bug</a></p>
        </body>
      </html>
    HTML
  end

end
