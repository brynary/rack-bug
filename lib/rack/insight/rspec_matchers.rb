module Rack::Insight
  module RspecMatchers

    RSpec::Matchers.define :have_row do |container, key, value|
      match do |response|
        if value
          response.should have_selector("#{container} tr", :content => key) do |row|
            row.should contain(value)
          end
        else
          response.should have_selector("#{container} tr", :content => key)
        end
      end

      failure_message_for_should do |response|
        "Expected: \n#{response.body}\nto have a row matching #{key}"
      end
    end

    RSpec::Matchers.define :have_li do |container, key, value|
      match do |response|
        if value
          response.should have_selector("#{container} li", :content => key) do |row|
            row.should contain(value)
          end
        else
          response.should have_selector("#{container} li", :content => key)
        end
      end

      failure_message_for_should do |response|
        "Expected: \n#{response.body}\nto have a li matching #{key}"
      end
    end

    RSpec::Matchers.define :have_heading do |text|
      match do |response|
        response.should have_selector("#rack-insight_toolbar li") do |heading|
          heading.should contain(text)
        end
      end

      failure_message_for_should do |response|
        "Expected: \n#{response.body}\nto have heading #{text}"
      end
    end

  end
end
