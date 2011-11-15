require File::expand_path("../../../spec_helper", __FILE__)
module Insight
  describe ActiveRecordPanel do
    before do
      mock_constant("ActiveRecord::Base")
      reset_insight :panel_classes => [ActiveRecordPanel]
    end

    def mock_model(name)
      model = stub("model")
      model.stub!(:name => name)
      obj = stub(name)
      obj.stub!(:base_class => model)
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
        response.should have_row("#active_record", "User", "2")
        response.should have_row("#active_record", "Group", "1")
      end
    end
  end
end
