require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  context "associations" do
    should have_many :ingests
  end
  
  context "validations" do
    should validate_presence_of :title
    # should validate_presence_of :slug
    should ensure_length_of(:title).is_at_most(255)
    
    should "validate presence of slug" do
      document = Document.new(:slug => "test")
      document.valid?
      assert_not_equal "test", document.slug
      assert_equal [], document.errors[:slug]
      
      document = Document.new
      document.valid?
      assert_equal [], document.errors[:slug]
    end
  end
  
  context "privacy mask" do
    should "set public" do
      @document = FactoryGirl.create(:document)
      @document.privacy = :public
      @document.save and @document.reload
      assert_equal [:public], @document.privacy
    end
  end
  
end
