=begin
require 'test_helper'

class Api::AuthorizationControllerTest < ActionController::TestCase
  setup do
    @controller = Api::AuthorizationController.new
    @client = FactoryGirl.create(:client, :platform => FactoryGirl.create(:platform, :cap => true))
    ENV.stubs(:[]).returns('5')
  end

  context "POST #client_authorize" do
    context "when there is no client available" do
      setup do
        @client.destroy
      end

      context "when client key is not passed" do
        should "raise RECORD_NOT_FOUND error" do
          post :client_authorize, {:format => :json}
          assert_response_attributes({"code"=>Api::Code::RECORD_NOT_FOUND})
        end
      end

      context "when client key is passed" do
        should "raise RECORD_NOT_FOUND error when passing bad client key" do
          post :client_authorize, {:format => :json, :client_key => "bad"}
          assert_response_attributes({"code"=>Api::Code::RECORD_NOT_FOUND})
        end
      end
    end
  end

  protected

  def assert_response_attributes(expected_attributes = {})
    params = response_body

    expected_attributes.keys.each do |attribute|
      assert params.has_key?(attribute), "should containt key '#{attribute}' in response '#{params}'"
    end

    expected_attributes.each do |key, value|
      assert_equal value, params[key], "'#{key}' should contain '#{value}', but was '#{params[key]}'"
    end
  end
end
=end
