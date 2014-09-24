require 'test_helper'

class Api::TagsControllerTest < ActionController::TestCase
  setup do
    @document1          = FactoryGirl.create(:document)
    @document1.tag_list = ["brown", "fox", "jumps", "over", "fence"]
    @document1.save

    @document2          = FactoryGirl.create(:document)
    @document2.tag_list = ["brown", "cats", "jump", "higher"]
    @document2.save
    
    @tag_count          = ActsAsTaggableOn::Tag.count
  end
  
  context "GET /api/tags" do
    should "get all tags" do
      get :index, format: :json
      assert_response :success
      assert response_body.has_key?("tags"), "should have root"
      assert_equal @tag_count, response_body["tags"].size, "should only return all tags"
      assert_attributes response_body["tags"].first
    end
    
    context "filters" do
      should "#limit" do
        get :index, :limit => 1, format: :json
        assert_response :success
        assert response_body.has_key?("tags"), "should have root"
        assert_equal 1, response_body["tags"].size
      end
      
      should "#most_used" do
        get :index, :most_used => 1, format: :json
        assert_response :success
        assert response_body.has_key?("tags"), "should have root"
        assert_equal 1, response_body["tags"].size
        assert_equal "brown", response_body["tags"].first["name"]
      end

      should "#least_used" do
        get :index, :least_used => 1, format: :json
        assert_response :success
        assert response_body.has_key?("tags"), "should have root"
        assert_equal 1, response_body["tags"].size
      end

      should "#named_like" do
        get :index, :named_like => "cat", format: :json
        assert_response :success
        assert response_body.has_key?("tags"), "should have root"
        assert_equal 1, response_body["tags"].size
        assert_equal "cats", response_body["tags"].first["name"]
      end
      
    end
  end
  
  context "GET /api/tags/count" do
    should "count" do
      get :count, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal @tag_count, response_body["count"], "should have count"
    end
  end
  
  protected
  
  def assert_response_body_with_upload_and_attributes(envelope = "upload")
    body = response_body
    assert body.has_key?(envelope.to_s), "should have envelope '#{envelope}'"
    assert_attributes body[envelope.to_s]
  end

  def assert_attributes(attributes)
    %w(id name taggings_count).each do |attribute|
      assert attributes.has_key?(attribute), "should containt attribute '#{attribute}' in '#{attributes}'"
    end
  end
end
