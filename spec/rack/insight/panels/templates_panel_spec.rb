require 'spec_helper'
require 'rack/insight/panels/templates_panel'

module Rack::Insight
  describe "TemplatesPanel" do
    before do
      mock_constant("ActionView::Template")
      reset_insight :panel_classes => [Rack::Insight::TemplatesPanel]
    end

    describe "heading" do
      it "displays the total rendering time" do
        response = get_via_rack "/"
        response.should have_heading("Templates: 0.00ms")
      end
    end

    def mock_template(path)
      template = double("ActionView::Template")
      template.stub(:virtual_path => path)
      template
    end

    describe "content" do
      it "displays the template paths" do
        app.before_return do
          mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show"))
        end
        response = get_via_rack "/"
        response.should contain("users/show")
      end

      it "displays the template children" do
        app.before_return do
          mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show")) do
            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/toolbar"))
          end
        end
        response = get_via_rack "/"
        response.should have_selector("div.panel_content#TemplatesPanel", :content => "users/show") do |li|
          li.should contain("users/toolbar")
        end
      end

      context "for templates that rendered templates" do
        it "displays the total time" do
          app.before_return do
            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show")) do
              mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/toolbar"))
            end
          end

          response = get_via_rack "/"
          response.should have_selector("div.panel_content#TemplatesPanel", :content => "users/show") do |li|
            li.should contain(TIME_MS_REGEXP)
          end
        end

        it "displays the exclusive and child times" do
          app.before_return do
            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show")) do
              mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/toolbar"))
            end
          end

          response = get_via_rack "/"
          response.should have_selector("div.panel_content#TemplatesPanel", :content => "users/show") do |li|
            li.should contain(/exclusive: \d\.\d{2}ms/)
            li.should contain(/child: \d\.\d{2}ms/)
          end
        end
      end

      context "for leaf templates" do
        it "does not display the exclusive time" do
          app.before_return do
            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show"))
          end

          response = get_via_rack "/"
          response.should contain("users/show") do |li|
            li.should_not contain("exclusive")
          end
        end
      end
    end
  end
end
