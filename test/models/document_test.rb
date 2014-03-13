require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  context "associations" do
    should have_many :ingests
    should have_many :segments
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
  
  context "document with ingests" do
    setup do
      @document = FactoryGirl.create(:document)
      @ingest   = FactoryGirl.create(:ingest_audio, :ingestable => @document)
    end
    
    should "have finshed transcribing" do
      @ingest.update_attribute(:aasm_state, "finished")
      assert_equal true, @document.trancribed?
    end
    
    should "not have finshed transcribing" do
      @ingest.update_attribute(:aasm_state, "started")
      assert_equal false, @document.trancribed?
    end
  end
  
end
