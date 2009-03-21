require "sinatra/base"

class SampleApp < Sinatra::Default

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
        </body>
      </html>
    HTML
  end
  
end