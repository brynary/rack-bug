require 'spec_helper'

if defined? Mongo
  module Rack::Insight
    describe "MongoPanel" do
      before do
        MongoPanel.reset
        reset_insight :panel_files => %w{mongo_panel}
      end

      describe "heading" do
        it "displays the total mongo time" do
          response = get_via_rack "/"
          response.should have_heading("Mongo: 0.00ms")
        end
      end

      describe "content" do
        describe "usage table" do
          it "displays the total number of mongo calls" do
            MongoPanel.record("db.user.user.find()") { }
            response = get_via_rack "/"

            # This causes a bus error:
            # response.should have_selector("th:content('Total Calls') + td", :content => "1")

            response.should have_row("#mongo_usage", "Total Calls", "1")
          end

          it "displays the total mongo time" do
            response = get_via_rack "/"
            response.should have_row("#mongo_usage", "Total Time", "0.00ms")
          end
        end

        describe "breakdown" do
          it "displays each mongo operation" do
            MongoPanel.record("db.user.user.find()") { }
            response = get_via_rack "/"
            response.should have_row("#mongo_breakdown", "db.user.user.find()")
          end

          it "displays the time for mongo call" do
            MongoPanel.record("db.user.user.find()") { }
            response = get_via_rack "/"
            response.should have_row("#mongo_breakdown", "db.user.user.find()", TIME_MS_REGEXP)
          end
        end
      end
    end
  end
end
