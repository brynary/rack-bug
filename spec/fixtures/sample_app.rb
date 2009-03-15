require "sinatra"

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
        <body>
          <p>Hello</p>
        </body>
      </html>
    HTML
  end
  
end