require 'test_helper'

class Web::RegistrationsControllerTest < ActionController::TestCase

  should "post" do
    assert_difference "Registration.count" do
      post :create, params: {:registration => {:email => "accepted@example.com", :time_zone => "America/Argentina/Buenos_Aires"}}
      assert_response :redirect
    end
  end

  should "xhr post" do
    assert_difference "Registration.count" do
      post :create, params: {:registration => {:email => "accepted@example.com", :time_zone => "America/Argentina/Buenos_Aires"}}, xhr: true
      assert_template "registrations/create"
    end
  end

end