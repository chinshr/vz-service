require 'test_helper'

class Api::StatusControllerTest < ActionController::TestCase

  setup do
    sign_out :user
  end

  context "[GET] /api/status(.:format)" do
    context "without auth" do

      should "#index" do
        get :index, format: :json
        assert_response :unauthorized
      end

    end

    context "with auth" do
      setup do
        @client_access = FactoryGirl.create(:client_access)
        @request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(@client_access.uid)
      end

      should "#index" do
        get :index, format: :json
        assert_response :success
        response_body = JSON.parse(response.body)
        assert response_body.keys.include?('status')
        assert_equal 1, response_body['code']
        assert_equal ["active_record", "api_version", "environment", "ruby_version", "rails_version", "database_adapter", "database_schema_version", "git_rev", "git_rev_short"].to_set,
          response_body['status'].keys.to_set
      end
    end
  end
end
