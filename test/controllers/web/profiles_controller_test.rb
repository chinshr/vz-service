require 'test_helper'

class Web::ProfilesControllerTest < ActionController::TestCase
  context "GET /@:id" do

    should "not be found" do
      assert_raises ActionController::RoutingError do
        get :show, :id => "@chinshr"
      end
    end

  end
end
