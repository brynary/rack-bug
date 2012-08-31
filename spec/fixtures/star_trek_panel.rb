class StarTrekPanel < Rack::Insight::Panel;

  def content_for_request(number)
    render_template "views/star_trek", :stats => {:captain => "Kirk", :ship => "Enterprise"}
  end
end
