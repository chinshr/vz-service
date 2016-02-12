require 'test_helper'

class Ingest::ImageIngestTest < ActiveSupport::TestCase
  context "associations" do
    subject { Ingest::ImageIngest.new }

    should belong_to(:ingestable)
    should have_many(:images).dependent(:destroy)
    should have_many(:images_with_removed).dependent(:destroy)

    should "have_many :images without removed" do
      ingest = FactoryGirl.create(:image_ingest, :ingestable_document)
      image = FactoryGirl.create(:image, ingest: ingest)
      assert_equal image, ingest.images.reload.first
      image.update_attribute(:removed_at, Time.zone.now)
      assert_equal nil, ingest.images.reload.first
      assert_equal image, ingest.images_with_removed.reload.first
    end
  end

  context "validations" do
    should validate_presence_of :ingestable
  end

  context "delegate" do
    setup do
      @ingest = FactoryGirl.create(:image_ingest, :ingestable_document)
    end

    should delegate :user, to: :ingestable
    should "delegate :user, to: :ingestable" do
      assert_equal @ingest.ingestable.user, @ingest.user
    end
  end

  context "#create" do
    should "with factory" do
      assert_difference "Ingest::ImageIngest.count" do
        @ingest = FactoryGirl.create(:image_ingest, :ingestable_document)
      end
    end

    should "from media source" do
      stub_request(:get, "http://www.example.com/the/best/image.jpg").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
        to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'image/jpeg'})
      media_ingest = FactoryGirl.create(:media_ingest_as_audio)

      assert_difference "Ingest::ImageIngest.count" do
        ingest = Ingest::ImageIngest.create({
          type: "Ingest::ImageIngest",
          ingestable: media_ingest.document,
          source_url: "http://www.example.com/the/best/image.jpg"
        })
      end
    end
  end

  should "#set_iteration" do
    @document = FactoryGirl.create(:document_with_track)
    ingest1 = FactoryGirl.create(:image_ingest, ingestable: @document)
    assert_equal 1, ingest1.iteration
    ingest1.increment!(:iteration)
    ingest2 = FactoryGirl.create(:image_ingest, ingestable: @document)
    assert_equal 3, ingest2.iteration
  end

  context "Model::S3" do
    setup do
      @ingest = FactoryGirl.create(:image_ingest, :ingestable_document)
    end

    should "#s3_bucket_name" do
      assert_equal "vz-test-assets-origin", @ingest.s3_origin_bucket_name
    end

    should "#s3_origin_url" do
      assert_equal "http://s3.amazonaws.com/vz-test-assets-origin/#{@ingest.uid}/#{@ingest.handle}", @ingest.s3_origin_url
    end

    context "#s3_origin_key" do
      should "be derived from uid and handle" do
        assert_equal "#{@ingest.uid}/#{@ingest.handle}", @ingest.s3_origin_key
      end

      should "be derived from origin_url" do
        @ingest.origin_url = "http://s3.amazonaws.com/vz-test-assets-origin/#{@ingest.uid}/#{@ingest.handle}"
        assert_equal "#{@ingest.uid}/#{@ingest.handle}", @ingest.s3_origin_key
      end
    end
  end
end