module CustomMatchers
  extend RSpec::Matchers::DSL

  define :have_row do |container, key, value|
    def match(container, key, value)
      if value
        response.should have_selector("#{container} tr", :content => key) do |row|
          row.should contain(value)
        end
      else
        response.should have_selector("#{container} tr", :content => key)
      end
    end
  end

  define :have_heading do |text|
    def match(text)
      response.should have_selector("#insight_toolbar li") do |heading|
        heading.should contain(text)
      end
    end
  end
end
