require 'test_helper'

class Web::DocumentsControllerTest < ActionController::TestCase

  context "GET /documents/:id" do
    context "when document is public" do
      setup do
        @document = FactoryGirl.create(:document, {:privacy => [:"public"]})
        assert_equal ["public"], @document.privacy
      end

      context "anyone can view" do
        setup do
          @document.update_attributes(accessibility: [:view])
          assert_equal true, @document.accessibility_viewable?
          assert_equal false, @document.accessibility_editable?
        end

        should "load without user session" do
          get :show, :id => @document.slug
          assert_response :redirect
          assert_match Regexp.new("http://test.host/@#{@document.user.username}/#{@document.slug}"), @response.redirect_url
        end

        should "load with document's signed in user" do
          sign_in @document.user
          get :show, :id => @document.slug
          assert_response :success
        end

        should "load with other signed in user should redirect to published page" do
          sign_in FactoryGirl.create(:user)
          get :show, :id => @document.slug
          assert_response :redirect
          assert_match Regexp.new("http://test.host/@#{@document.user.username}/#{@document.slug}"), @response.redirect_url
        end
      end
    end

    context "when document is private" do
      setup do
        @document = FactoryGirl.create(:document, {:privacy => [:"private"]})
        assert_equal ["private"], @document.privacy
        assert_equal [], @document.accessibility
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

      context "anyone can view" do
        setup do
          @document.update_attributes(accessibility: [:view])
          assert_equal true, @document.accessibility_viewable?
          assert_equal false, @document.accessibility_editable?
        end

        should "be editable by owner" do
          sign_in @document.user
          get :edit, :id => @document.slug
          assert_response :success
        end

        should "redirect to sign in without user session" do
          get :edit, :id => @document.slug
          assert_response :redirect
        end

        should "not be editable by anyone else" do
          sign_in FactoryGirl.create(:user)
          get :edit, :id => @document.slug
          assert_response :unauthorized
        end
      end

      context "anyone can edit" do
        setup do
          @document.update_attributes(accessibility: [:edit])
          assert_equal true, @document.accessibility_viewable?
          assert_equal true, @document.accessibility_editable?
        end

        should "be editable by owner" do
          sign_in @document.user
          get :edit, :id => @document.slug
          assert_response :success
        end

        should "not be editable by anonymous user" do
          get :edit, :id => @document.slug
          assert_response :redirect
        end

        should "be editable by any user" do
          sign_in FactoryGirl.create(:user)
          get :edit, :id => @document.slug
          assert_response :success
        end
      end
    end

  end

end
