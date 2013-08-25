# The SpeedTracerPanel needs to be updated to follow the RackInsight pattern.  Until then there is no sense in these tests.
#require 'spec_helper'
#
#module Rack::Insight
#  describe "SpeedTracerPanel" do
#    before do
#      mock_constant("ActionView::Template")
#      reset_insight :panel_files => %w{speedtracer_panel}
#    end
#
#    describe "heading" do
#      it "lists traces" do
#        response = get_via_rack "/"
#        response.should have_heading("traces")
#      end
#    end
#
#    def mock_template(path)
#      template = double("ActionView::Template")
#      template.stub!(:virtual_path => path)
#      template
#    end
#
#    describe "content", :pending => "time to build good Speedtracer tests" do
#      it "displays the template paths" do
#        app.before_return do
#          mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show"))
#        end
#        response = get_via_rack "/"
#        response.should contain("users/show")
#      end
#
#      it "displays the template children" do
#        app.before_return do
#          mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show")) do
#            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/toolbar"))
#          end
#        end
#        response = get_via_rack "/"
#        response.should have_selector("li", :content => "users/show") do |li|
#          li.should contain("users/toolbar")
#        end
#      end
#
#      context "for templates that rendered templates" do
#        it "displays the total time" do
#          app.before_return do
#            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show")) do
#              mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/toolbar"))
#            end
#          end
#
#          response = get_via_rack "/"
#          response.should have_selector("li", :content => "users/show") do |li|
#            li.should contain(TIME_MS_REGEXP)
#          end
#        end
#
#        it "displays the exclusive time" do
#          app.before_return do
#            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show")) do
#              mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/toolbar"))
#            end
#          end
#
#          response = get_via_rack "/"
#          response.should have_selector("li", :content => "users/show") do |li|
#            li.should contain(/\d\.\d{2} exclusive/)
#          end
#        end
#      end
#
#      context "for leaf templates" do
#        it "does not display the exclusive time" do
#          app.before_return do
#            mock_method_call("ActionView::Template", :render, [], :instance, mock_template("users/show"))
#          end
#
#          response = get_via_rack "/"
#          response.should contain("users/show") do |li|
#            li.should_not contain("exclusive")
#          end
#        end
#      end
#    end
#  end
#end
