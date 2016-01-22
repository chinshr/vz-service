require 'test_helper'

class Web::Profiles::DocumentsControllerTest < ActionController::TestCase

  context "GET /documents/@:user_id/:id" do

    context "when private document" do
      setup do
        @document = FactoryGirl.create(:document,
          {privacy: [:private], accessibility: []})
        assert_equal ["private"], @document.privacy
        assert_equal false, @document.published?
      end

      should "not load with anonymous" do
        get :show, user_id: "@#{@document.user.username}", id: @document.slug
        assert_response :unauthorized
      end

      should "not load with any user" do
        sign_in FactoryGirl.create(:user)
        get :show, user_id: "@#{@document.user.username}", id: @document.slug
        assert_response :unauthorized
      end
    end

    [:public, :unlisted].each do |privacy|
      context "when #{privacy} document" do
        setup do
          @document = FactoryGirl.create(:document_with_track,
            {privacy: [privacy], accessibility: [:view]})
          assert_equal ["#{privacy}"], @document.privacy
        end

        context "is published" do
          setup do
            assert_equal true, @document.publish!
          end

          should "load with anonymous user" do
            get :show, user_id: "@#{@document.user.username}", id: @document.slug
            assert_response :success
          end

          should "load with document's signed in user" do
            sign_in @document.user
            get :show, user_id: "@#{@document.user.username}", id: @document.slug
            assert_response :success
          end

          should "load with any user" do
            sign_in FactoryGirl.create(:user)
            get :show, user_id: "@#{@document.user.username}", id: @document.slug
            assert_response :success
          end

          should "load mp3 and redirect to S3 url" do
            get :show, user_id: "@#{@document.user.username}", id: @document.slug, format: "mp3"
            assert_response :redirect
          end

          should "load and render srt" do
            get :show, user_id: "@#{@document.user.username}", id: @document.slug, format: "srt"
            assert_response :success
            assert_template "show"
          end

        end

        context "is not published" do
          setup do
            assert_equal true, @document.unpublish!
          end

          should "not load with anonymous user" do
            get :show, user_id: "@#{@document.user.username}", id: @document.slug
            assert_response :unauthorized
          end
        end
      end
    end
  end

end
