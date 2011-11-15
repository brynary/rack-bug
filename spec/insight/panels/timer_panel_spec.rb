module Insight
  describe TimerPanel do
    before do
      reset_insight :panel_classes => [TimerPanel]
    end

    describe "heading" do
      it "displays the elapsed time" do
        response = get_via_rack "/"
        response.should have_heading(TIME_MS_REGEXP)
      end
    end

    describe "content" do
      it "displays the user CPU time" do
        response = get_via_rack "/"
        response.should have_row("#timer", "User CPU time", TIME_MS_REGEXP)
      end

      it "displays the system CPU time" do
        response = get_via_rack "/"
        response.should have_row("#timer", "System CPU time", TIME_MS_REGEXP)
      end

      it "displays the total CPU time" do
        response = get_via_rack "/"
        response.should have_row("#timer", "Total CPU time", TIME_MS_REGEXP)
      end

      it "displays the elapsed time" do
        response = get_via_rack "/"
        response.should have_row("#timer", "Elapsed time", TIME_MS_REGEXP)
      end
    end
  end
end
