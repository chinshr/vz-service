require 'test_helper'

class Web::DocumentsControllerTest < ActionController::TestCase

  context "GET /documents/:id" do
    context "when document is public" do
      setup do
        @document = FactoryGirl.create(:document, {:privacy => [:"public"]})
        assert_equal ["public"], @document.privacy
      end
      
      should "load without user session" do
        get :show, :id => @document.slug
        assert_response :success
      end

      should "load with document's signed in user" do
        sign_in @document.user
        get :show, :id => @document.slug
        assert_response :success
      end

      should "load with other signed in user" do
        sign_in FactoryGirl.create(:user)
        get :show, :id => @document.slug
        assert_response :success
      end
    end
    
    context "when document is private" do
      setup do
        @document = FactoryGirl.create(:document, {:privacy => [:"private"]})
        assert_equal ["private"], @document.privacy
      end

      should "load with document's user" do
        sign_in @document.user
        get :show, :id => @document.slug
        assert_response :success
      end

      should "redirect to sign in without user session" do
        get :show, :id => @document.slug
        assert_response :redirect
      end
      
      should "raise unauthorized with other signed in user" do
        sign_in FactoryGirl.create(:user)
        get :show, :id => @document.slug
        assert_response :unauthorized
      end
    end
  end

  context "GET /documents/:id/edit" do
    context "when document is public" do
      setup do
        @document = FactoryGirl.create(:document, {:privacy => [:"public"]})
        assert_equal ["public"], @document.privacy
      end

      should "be editable with document's signed in user" do
        sign_in @document.user
        get :edit, :id => @document.slug
        assert_response :success
      end

      should "redirect to sign in without user session" do
        get :edit, :id => @document.slug
        assert_response :redirect
      end

      should "not be editable for other signed in user" do
        sign_in FactoryGirl.create(:user)
        get :edit, :id => @document.slug
        assert_response :unauthorized
      end
    end
    
  end

end
