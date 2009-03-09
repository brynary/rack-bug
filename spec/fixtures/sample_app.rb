require "sinatra"

class SampleApp < Sinatra::Default
  
  get "/" do
    <<-HTML
      <html>
        <body>
          <p>Hello</p>
        </body>
      </html>
    HTML
  end
  
end