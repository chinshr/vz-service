require 'test_helper'

class Api::Ingests::WorkersControllerTest < ActionController::TestCase
  setup do
    @user1    = FactoryGirl.create(:user)
    @user2    = FactoryGirl.create(:backend_user)
    @ingest   = FactoryGirl.create(:media_ingest_as_audio)
    sign_out :user
  end

  context "POST /api/ingests/:ingest_id/workers.json" do
    context "as backend user" do
      setup do
        sign_in :user, @user2
      end

      should "#create" do
        messages = {"harvest" => {"message" => "test"}}
        assert_difference "Ingest::Worker.count", 1 do
          post :create, ingest_id: @ingest.id, worker: {
            ingest_iteration: 1,
            worker_name: "ingest/media_ingest/harvest_worker",
            messages: messages
          }, format: :json
        end
        assert_response :success
        assert_attributes response_body["worker"]
        assert_equal 1, response_body["worker"]["ingest_iteration"]
        assert_equal "ingest/media_ingest/harvest_worker", response_body["worker"]["worker_name"]
        assert_equal "created", response_body["worker"]["state"]
        assert_equal messages, response_body["worker"]["messages"]
      end

      should "#create and start" do
        assert_difference "Ingest::Worker.count", 1 do
          post :create, ingest_id: @ingest.id, worker: {
            worker_name: "ingest/media_ingest/harvest_worker",
            event: "start"
          }, format: :json
        end
        assert_response :success
        assert_attributes response_body["worker"]
        assert_equal @ingest.iteration, response_body["worker"]["ingest_iteration"]
        assert_equal "ingest/media_ingest/harvest_worker", response_body["worker"]["worker_name"]
        assert_equal "running", response_body["worker"]["state"]
      end

      should "#create with errors" do
        assert_no_difference "Ingest::Worker.count" do
          post :create, ingest_id: @ingest.id, worker: {
            worker_name: ""
          }, format: :json
        end
        assert_response :unprocessable_entity
        assert_attributes response_body["worker"]
        assert_equal Api::Code::VALIDATION_ERROR, response_body["code"]
        assert_equal true, response_body["worker"].has_key?("errors")
      end
    end

    should "be unauthorized without user" do
      post :create, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      post :create, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end
  end

  context "GET /api/ingests/:ingest_id/workers(.:format)" do
    setup do
      Ingest::Worker.destroy_all
    end

    should "be unauthorized without user" do
      get :index, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized for none backend users" do
      sign_in :user, @user1
      get :index, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end

    should "all workers when signed in as backend user" do
      FactoryGirl.create(:ingest_worker, ingest_id: @ingest.id)
      sign_in :user, @user2
      get :index, ingest_id: @ingest.id, format: :json
      assert_response :success
      assert response_body.has_key?("workers"), "should have root"
      assert_equal 1, response_body["workers"].size, "should have worker"
      assert_attributes response_body["workers"].first
      assert_equal false, response_body["workers"].first.has_key?("ingest")
    end
  end

  context "GET /api/ingests/:ingest_id/workers/count(.:format)" do
    should "be unauthorized whithout any user" do
      get :count, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :count, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end

    should "count workers when signed in as backend user" do
      sign_in :user, @user2
      get :count, ingest_id: @ingest.id, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal Ingest::Worker.count, response_body["count"], "should have count"
    end
  end

  context "GET /api/ingests/:ingest_id/workers/:id" do
    setup do
      @worker1 = FactoryGirl.create(:ingest_worker, ingest_id: @ingest.id)
    end

    should "be unauthorized whithout any user" do
      get :show, :ingest_id => @ingest.id, :id => @worker1.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :show, :ingest_id => @ingest.id, :id => @worker1.id, format: :json
      assert_response :unauthorized
    end

    should "get worker when signed in as backend user" do
      sign_in :user, @user2
      get :show, :ingest_id => @ingest.id, :id => @worker1.id, format: :json
      assert_response :success
      assert_attributes response_body["worker"]
      assert_equal @ingest.id, response_body["worker"]["ingest_id"]
      assert_equal true, response_body["worker"].has_key?("ingest")
    end
  end

  context "PUT /api/ingests/:ingest_id/workers/:id(.:format)" do
    setup do
      @worker1 = FactoryGirl.create(:ingest_worker, ingest_id: @ingest.id)
    end

    should "be unauthorized whithout any user" do
      put :update, :ingest_id => @ingest.id, :id => @worker1.id, format: :json
      assert_response :unauthorized
    end

    context "as backend user" do
      setup do
        sign_in :user, @user1
      end

      should "update worker to start with #event=" do
        sign_in :user, @user2
        assert_equal :created, @worker1.state
        put :update, {:ingest_id => @ingest.id, :id => @worker1.id, :worker => {
          event: "start",
          lock_count: 1
        }, format: :json}
        assert_response :success
        assert_response_body_attributes_with "worker"
        assert_equal "running", response_body["worker"]["state"]
        assert_equal 1, response_body["worker"]["lock_count"]
      end

      should "update worker to start with #status=" do
        sign_in :user, @user2
        assert_equal :created, @worker1.state
        put :update, {:ingest_id => @ingest.id, :id => @worker1.id, :worker => {
          status: Ingest::Worker::STATE_RUNNING
        }, format: :json}
        assert_response :success
        assert_response_body_attributes_with "worker"
        assert_equal "running", response_body["worker"]["state"]
      end

      should "update worker with instance_id" do
        messages = {"harvest" => {"message" => "test"}}

        @server = FactoryGirl.create(:cpw_ingest_server)
        sign_in :user, @user2
        assert_equal :created, @worker1.state
        put :update, {:ingest_id => @ingest.id, :id => @worker1.id, :worker => {
          instance_id: @server.instance_id,
          messages: messages,
          progress: 18
        }, format: :json}
        assert_response :success
        assert_response_body_attributes_with "worker"
        assert_equal @server.id, response_body["worker"]["server_id"]
        assert_equal @server.instance_id, response_body["worker"]["instance_id"]
        assert_equal messages, response_body["worker"]["messages"]
        assert_equal 18, response_body["worker"]["progress"]
      end

      should "not update running worker with #event=start" do
        @worker1.update_attribute(:aasm_state, "running")
        assert_equal :running, @worker1.state
        sign_in :user, @user2
        put :update, {:ingest_id => @ingest.id, :id => @worker1.id, :worker => {
          event: "start"
        }, format: :json}
        assert_response :unprocessable_entity
        assert_equal Api::Code::VALIDATION_ERROR, response_body["code"]
        assert_response_body_attributes_with "worker"
        assert_equal true, response_body["worker"].has_key?("errors")
      end

    end

    should "not update unknown worker" do
      sign_in :user, @user2
      put :update, {:ingest_id => -1, :id => -1, format: :json}
      assert_response :not_found
    end

    should "not update worker of different ingest" do
      sign_in :user, @user2
      put :update, {:ingest_id => -1, :id => @worker1.id, format: :json}
      assert_response :not_found
    end
  end

  context "DELETE /api/ingests/:ingest_id/workers/:id(.:format)" do
    setup do
      @worker1 = FactoryGirl.create(:ingest_worker, ingest_id: @ingest.id)
    end

    should "be unauthorized without user" do
      delete :destroy, {ingest_id: @ingest, id: @worker1.id, format: :json}
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      delete :destroy, {ingest_id: @ingest, id: @worker1.id, format: :json}
      assert_response :unauthorized
    end

    should "destroy with backend user" do
      sign_in :user, @user2
      assert_difference "Ingest::Worker.count", -1 do
        delete :destroy, {ingest_id: @ingest.id, id: @worker1.id, format: :json}
        assert_response :success
        assert_attributes response_body["worker"]
      end
    end
  end

  protected

  def assert_attributes(response, expected_attributes = {})
    %w(id uid state status ingest_iteration worker_name created_at started_at stopped_at finished_at ingest_id server_id messages progress).each do |key|
      assert response.has_key?(key), "should contain key '#{key}' in '#{response}'"
    end
  end
end
