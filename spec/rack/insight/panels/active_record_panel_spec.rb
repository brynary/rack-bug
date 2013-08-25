require 'spec_helper'
require 'rack/insight/panels/active_record_panel'

module Rack::Insight
  describe "ActiveRecordPanel" do
    before do
      mock_constant("ActiveRecord::Base")
      reset_insight :panel_classes => [Rack::Insight::ActiveRecordPanel]
    end

    def mock_model(name)
      model = double("model")
      model.stub(:name => name)
      obj = double(name)
      obj.stub(:base_class => model)
      obj
    end

    describe "heading" do
      it "displays the total number of instantiated AR objects" do
        app.before_return do
          mock_method_call("ActiveRecord::Base", "allocate", [], :class, mock_model("User"))
          mock_method_call("ActiveRecord::Base", "allocate", [], :class, mock_model("Group"))
        end

        response = get_via_rack "/"
        response.should have_heading("2 AR Objects")
      end
    end

    describe "content" do
      it "displays the count of instantiated objects for each class" do
        app.before_return do
          mock_method_call("ActiveRecord::Base", "allocate", [], :class, mock_model("User"))
          mock_method_call("ActiveRecord::Base", "allocate", [], :class, mock_model("User"))
          mock_method_call("ActiveRecord::Base", "allocate", [], :class, mock_model("Group"))
        end
        response = get_via_rack "/"
        response.should have_row("#ActiveRecordPanel", "User", "2")
        response.should have_row("#ActiveRecordPanel", "Group", "1")
      end
    end
  end
end
