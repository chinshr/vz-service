require 'test_helper'

class Web::ProfilesControllerTest < ActionController::TestCase
  context "GET /@:id" do
    setup do
      @user = FactoryGirl.create(:user)
    end

    should "be found" do
      get :show, params: {:id => "@#{@user.username}"}
      assert_response :success
    end

  end
end
