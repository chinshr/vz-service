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
  
  should "calculate average score and duration" do
    document = FactoryGirl.create(:document)
    segment1 = FactoryGirl.create(:document_segment, :offset => 0, :document => document, :score => 0)
    segment2 = FactoryGirl.create(:document_segment, :offset => 1, :document => document, :score => 0.5)
    segment3 = FactoryGirl.create(:document_segment, :offset => 2, :document => document, :score => 1)
    assert_equal 3, document.segments.count
    assert_equal 0.5, document.score.to_f
    assert_equal 10.53, document.duration.to_f
  end

  should "order segments by offset" do
    document = FactoryGirl.create(:document)
    segment3 = FactoryGirl.create(:document_segment, :offset => 2, :document => document, :score => 1)
    segment1 = FactoryGirl.create(:document_segment, :offset => 0, :document => document, :score => 0)
    segment2 = FactoryGirl.create(:document_segment, :offset => 1, :document => document, :score => 0.5)
    assert_equal 3, document.segments.count
    assert_equal segment1, document.segments[0]
    assert_equal segment2, document.segments[1]
    assert_equal segment3, document.segments[2]
  end
  
end
