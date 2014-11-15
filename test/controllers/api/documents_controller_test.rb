require 'test_helper'

class Api::DocumentsControllerTest < ActionController::TestCase
  setup do
    @user1              = FactoryGirl.create(:user)
    @user2              = FactoryGirl.create(:user)
    
    @document1          = FactoryGirl.create(:document)
    @document1.privacy  = [:"public"]
    @document1.user     = @user1
    @document1.tag_list = ["brown", "fox", "jumps", "over", "fence"]
    @document1.save

    @document2          = FactoryGirl.create(:document)
    @document2.privacy  = [:"private"]
    @document2.user     = @user2
    @document2.tag_list = ["brown", "cats", "jump", "higher"]
    @document2.save
    
    sign_out :user
  end
  
  context "GET /api/documents" do
    should "all public documents when not signed in" do
      get :index, format: :json
      assert_response :success
      assert response_body.has_key?("documents"), "should have root"
      assert_equal 1, response_body["documents"].size, "should only return public documents"
      assert_attributes response_body["documents"].first
    end

    should "all public and user's private documents when signed in" do
      sign_in :user, @user2
      get :index, format: :json
      assert_response :success
      assert response_body.has_key?("documents"), "should have root"
      assert_equal 2, response_body["documents"].size, "should only return public documents"
      assert_attributes response_body["documents"].first
    end
  end
  
  context "GET /api/documents/count" do
    should "count public documents when no user is signed in" do
      get :count, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal Document.with_privacy("public").count, response_body["count"], "should have count"
    end

    should "count public and user's private documents when user is signed in" do
      sign_in :user, @user2
      get :count, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal Document.with_user_privacy(@user2).count, response_body["count"], "should have count"
    end
  end

  context "GET /api/documents/:id" do
    should "get public document when not signed in" do
      get :show, :id => @document1, format: :json
      assert_response :success
      assert_response_body_attributes_with "document"
    end

    should "not get private document when not signed in" do
      get :show, :id => @document2, format: :json
      assert_response :unauthorized
    end

    should "get user 2's private document when signed in as user 2" do
      sign_in :user, @user2
      get :show, :id => @document2, format: :json
      assert_response :success
    end

    should "not get user 2's private document when signed in as user 1" do
      sign_in :user, @user1
      get :show, :id => @document2, format: :json
      assert_response :unauthorized
    end
  end
  
  context "PUT /api/documents/:id" do
    should "update user 2's document when signed in as user 2" do
      sign_in :user, @user2
      put :update, {:id => @document2.id, :document => {:title => "La fiesta!", :description => "Entrevista en la fiesta.", 
        :tag_list => ["entrevista", "fiesta"], locale: "es-AR", :privacy => "private", :content => "Es el contenido."}, format: :json}
      assert_response :success
      assert_response_body_attributes_with "document"
      assert_equal "La fiesta!", @document2.reload.title
      assert_equal "Entrevista en la fiesta.", @document2.reload.description
      assert_equal ["entrevista", "fiesta"], @document2.reload.tag_list
      assert_equal "es-AR", @document2.reload.locale
      assert_equal ["private"], @document2.reload.privacy
      assert_equal "Es el contenido.", @document2.reload.content
    end
    
    should "NOT update when no user is signed in " do
      put :update, {:id => @document1.id, :document => {:title => "No autorizado!"}, format: :json}
      assert_response :unauthorized
    end

    should "NOT update public document when user 2 is signed in" do
      sign_in :user, @user2
      put :update, {:id => @document1.id, :document => {:title => "No autorizado!"}, format: :json}
      assert_response :unauthorized
    end

    should "NOT update user 2's private document when user 1 is signed in" do
      sign_in :user, @user1
      put :update, {:id => @document2.id, :document => {:title => "No autorizado!"}, format: :json}
      assert_response :unauthorized
    end
  end

  context "DELETE /api/documents/:id" do
    should "destroy user 2's document when signed in as user 2" do
      sign_in :user, @user2
      assert_difference 'Document.count', -1 do
        delete :destroy, {id: @document2, format: :json}
        assert_response :success
        assert_response_body_attributes_with "document"
      end
    end

    should "NOT destroy user 1's public document when signed in as user 2" do
      sign_in :user, @user2
      assert_no_difference 'Document.count' do
        delete :destroy, {id: @document1, format: :json}
        assert_response :unauthorized
      end
    end
    
    should "NOT destroy when not signed in" do
      assert_no_difference 'Document.count' do
        delete :destroy, {id: @document1, format: :json}
        assert_response :unauthorized
      end
    end
  end
  
  protected
  
  def assert_attributes(params, expected_attributes = [])
    (expected_attributes + %w(id title description)).each do |attribute|
      assert params.has_key?(attribute), "should containt attribute '#{attribute}' in '#{params}'"
    end
  end
end
