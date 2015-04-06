require 'test_helper'

class Api::AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @client = FactoryGirl.create(:client, :platform => FactoryGirl.create(:platform, :cap => true))
    ENV.stubs(:[]).returns('5')
  end

  context "POST #client_authorize" do
    context "when there is no client available" do
      setup do
        @client.destroy
      end

      context "when client key is not passed" do
        should "ARGUMENT_MISSING client_key" do
          post "/api/authorize/client", {:format => :json}
          assert_response_attributes({"code"=>Api::Code::ARGUMENT_MISSING})
        end
      end

      context "correct client_key is passed" do
        should "ARGUMENT_MISSING device_uid" do
          post "/api/authorize/client", {:format => :json, :client_key => "bad"}
          assert_response_attributes({"code"=>Api::Code::ARGUMENT_MISSING})
        end
      end
    end

    context "when there is a client available" do
      context "when client key is passed" do
        context "when device_uid is not passed" do
          should "raise ARGUMENT_MISSING error when passing bad client key" do
            post "/api/authorize/client", {:format => :json, :client_key => "bad"}
            assert_response_attributes({"code"=>Api::Code::ARGUMENT_MISSING})
          end

          should "should raise ARGUMENT_MISSING error" do
            post "/api/authorize/client", {:format => :json, :client_key => @client.key}
            assert_response_attributes({"code"=>Api::Code::ARGUMENT_MISSING})
          end
        end

        context "when device_uid is passed" do
          should "create client_access and return access_token and access_secret on success" do
            assert_difference "Api::ClientAccess.count", 1 do
              post "/api/authorize/client", {:format => :json,
                :client_key => @client.key, :device_uid => "12345"}
              assert_response :success
              last_access = Api::ClientAccess.last
              assert_not_nil last_access
              assert_response_attributes({"access_token" => last_access.uid, "access_secret" => last_access.access_secret})
            end
          end

          should "have all the proper tags in response" do
            post "/api/authorize/client", {:format => :json, :client_key => @client.key, :device_uid => "12345"}
            assert_response :success
            auth = response_body
            assert_equal 3, auth.keys.length
            assert_equal true, auth.include?("access_token")
            assert_equal true, auth.include?("access_secret")
            assert_equal false, auth.include?("errors")
            assert_equal true, auth.include?("code")
            assert_equal Api::Code::SUCCESS, auth["code"]
          end

          should "replace client access with new one when authorizing same device_uid" do
            assert_difference "Api::ClientAccess.count", 1 do
              post "/api/authorize/client", {:format => :json, :client_key => @client.key, :device_uid => "12345"}
              assert_response :success
              post "/api/authorize/client", {:format => :json, :client_key => @client.key, :device_uid => "12345"}
              assert_response :success
              last_access = Api::ClientAccess.last
              assert_not_nil last_access
              assert_response_attributes({"access_token" => last_access.uid, "access_secret" => last_access.access_secret})
            end
          end
        end
      end
    end
  end

  context "POST #user_authorize" do
    context "when passing invalid access token" do
      setup do
        @client_access = FactoryGirl.create(:client_access)
        @user = FactoryGirl.create(:user)
      end

      should "raise AUTHORIZATION_ERROR when not passing access_token" do
        params = {format: :json, email: @user.email,
          password: @user.password}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response :unauthorized
        assert_response_attributes({"code" => Api::Code::AUTHORIZATION_ERROR,
          "errors" => {"base" => ["Authorization error: access_token"]}})
      end

      should "raise AUTHORIZATION_ERROR when passing bad access_token" do
        params = {format: :json, access_id: "bad",
          email: @user.email, password: @user.password}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response :unauthorized
        assert_response_attributes({"code" => Api::Code::AUTHORIZATION_ERROR,
          "errors" => {"base" => ["Authorization error: access_token"]}})
      end
    end

    context "when passing invalid user credentials" do
      setup do
        @client_access = FactoryGirl.create(:client_access)
        @user = FactoryGirl.create(:user)
      end

      should "raise ARGUMENT_MISSING error when not passing email" do
        params = {format: :json, access_token: @client_access.uid,
          password: @user.password}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response_attributes({"code" => Api::Code::ARGUMENT_MISSING})
        assert_response :unprocessable_entity
      end

      should "raise RECORD_NOT_FOUND error when passing bad email" do
        params = {format: :json, access_token: @client_access.uid,
          email: "bad", password: "password"}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response_attributes({"code" => Api::Code::RECORD_NOT_FOUND})
        assert_response :missing
      end

      should "raise AUTHORIZATION_ERROR error when not passing password" do
        params = {format: :json, access_token: @client_access.uid,
          email: @user.email}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response :unprocessable_entity
        assert_response_attributes({"code" => Api::Code::ARGUMENT_MISSING})
        assert_response :unprocessable_entity
      end

      should "raise AUTHORIZATION_ERROR error when passing bad password" do
        params = {format: :json, access_token: @client_access.uid,
          email: @user.email, password: "bad"}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response_attributes({"code" => Api::Code::AUTHORIZATION_ERROR})
        assert_response :unauthorized
      end
    end

    context "when passing valid user credentials" do
      setup do
        @client_access = FactoryGirl.create(:client_access)
        @user = FactoryGirl.create(:user)
      end

      should "successfully upgrade client access for user authorization" do
        params = {format: :json, access_token: @client_access.uid,
           email: @user.email, password: @user.password}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response :success
        assert_equal @user.id, @client_access.reload.user_id
        assert_equal Api::ClientAccess::ACCESS_STATUS_ACCOUNT, @client_access.reload.access_status
      end

      should "not have same client access with device_uid" do
        device_uid = "123456"
        old_client_access = @client.client_accesses.create(:device_uid => device_uid, :user_id => @user.id)
        client_access = @client.client_accesses.create(:device_uid => device_uid)
        params = {format: :json, access_token: @client_access.uid,
          email: @user.email, password: @user.password}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response :success
        assert_equal 1, Api::ClientAccess.where(device_uid: device_uid, user_id: @user.id).count
      end

      should "raise AUTHORIZATION_ERROR error when signing in with inactive user" do
        @user = FactoryGirl.create(:unconfirmed_user)
        assert_equal false, @user.active?
        params = {format: :json, access_token: @client_access.uid,
          email: @user.email, password: @user.password}.with_indifferent_access
        post "/api/authorize/user", params
        assert_response_attributes({"code" => Api::Code::AUTHORIZATION_ERROR})
        assert_response :unauthorized
      end
    end
  end

  context "GET #status" do
    setup do
      @client_access = FactoryGirl.create(:client_access, :access_status => Api::ClientAccess::ACCESS_STATUS_CLIENT)
      @params = {format: :json, access_token: @client_access.uid}.with_indifferent_access
    end

    should "return record not found for wrong access_token" do
      @params[:access_token] = 'wrong'
      get "/api/authorize/status", @params
      assert_response :unauthorized
      assert_response_attributes("code" => Api::Code::AUTHORIZATION_ERROR)
    end

    should "return SUCCESS with access_token and access_status = client" do
      get "/api/authorize/status", @params
      assert_response :success
      assert_response_attributes("code" => Api::Code::SUCCESS,
        "access_status" => Api::ClientAccess::ACCESS_STATUS_CLIENT)
    end

    should "return SUCCESS with access_token and return access_status = account" do
      @user = FactoryGirl.create(:user)
      post "/api/authorize/user", {format: :json, access_token: @client_access.uid,
        email: @user.email, password: @user.password}.with_indifferent_access
      assert_response :success
      get "/api/authorize/status", @params
      assert_response :success
      assert_response_attributes("code" => Api::Code::SUCCESS,
        "access_status" => Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
    end
  end

  context "DELETE #user_deauthorize" do
    context "when passing invalid access_token" do
      setup do
        @client_access = FactoryGirl.create(:client_access)
        @user = FactoryGirl.create(:user)
      end

      should "raise AUTHORIZATION_ERROR error when not passing access_token" do
        params = {format: :json, email: @user.email,
          password: @user.password}.with_indifferent_access
        delete "/api/authorize/user", params
        assert_response_attributes("code" => Api::Code::AUTHORIZATION_ERROR)
        assert_response :unauthorized
      end

      should "raise AUTHORIZATION_ERROR error when passing bad access_token" do
        params = {format: :json, email: @user.email,
          password: @user.password, access_token: "bad"}.with_indifferent_access
        delete "/api/authorize/user", params
        assert_response_attributes("code" => Api::Code::AUTHORIZATION_ERROR)
        assert_response :unauthorized
      end
    end

    context "when passing corret access_token" do
      setup do
        @user = FactoryGirl.create(:user)
      end

      should "succeed if account is connected" do
        @client_access = FactoryGirl.create(:client_access, user: @user, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
        params = {format: :json, access_token: @client_access.uid}.with_indifferent_access
        assert_equal @user, @client_access.user
        delete "/api/authorize/user", params
        assert_response :success
        # assert_response_attributes("code" => Api::Code::SUCCESS)
        assert_equal nil, @client_access.reload.user
        assert_equal Api::ClientAccess::ACCESS_STATUS_CLIENT, @client_access.reload.access_status
      end

      should "fail if account is not connected" do
        @client_access = FactoryGirl.create(:client_access, :access_status => Api::ClientAccess::ACCESS_STATUS_CLIENT)
        params = {format: :json, access_token: @client_access.uid}.with_indifferent_access
        delete "/api/authorize/user", params
        assert_response_attributes("code" => Api::Code::AUTHORIZATION_ERROR)
        assert_response :unauthorized
        assert_equal Api::ClientAccess::ACCESS_STATUS_CLIENT, @client_access.reload.access_status
      end
    end
  end

  protected

  def assert_response_attributes(expected_attributes = {})
    params = response_body

    expected_attributes.keys.each do |attribute|
      assert params.has_key?(attribute), "should contain key '#{attribute}' in response '#{params}'"
    end

    expected_attributes.each do |key, value|
      assert_equal value, params[key], "'#{key}' should contain '#{value}', but was '#{params[key]}'"
    end
  end

  def response_body
    JSON.parse(response.body)
  end

end
