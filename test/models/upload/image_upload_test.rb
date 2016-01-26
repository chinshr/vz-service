require 'test_helper'

class Upload::ImageUploadTest < ActiveSupport::TestCase

  context "instantiate" do
    should "with type" do
      upload = Upload.new(type: "Upload::ImageUpload")
      assert_equal Upload::ImageUpload, upload.class

      upload = Upload.new(type: "image_upload")
      assert_equal Upload::ImageUpload, upload.class
    end

    should "with image ingest" do
      upload = Upload.new(type: "Upload::ImageUpload")
      assert_not_nil upload.ingest
      assert_equal Ingest::ImageIngest, upload.ingest.class
    end
  end

  should "create" do
    document = FactoryGirl.create(:document_with_track)
    assert_difference "Upload::ImageUpload.count" do
      assert_difference "Ingest::ImageIngest.count" do
        upload = Upload.create({
          type: "Upload::ImageUpload",
          ingestable_id: document.id,
          ingestable_type: document.class.name,
          file_name: "test.jpg",
          file_size: 123456,
          file_type: "image/jpeg",
          source_url: "http://s3.amazonaws.com/vz-test-dropbox/test.jpg"
        })
        assert_equal :starting, upload.state
      end
    end
  end

  context "delegate" do
    setup do
      @upload = Upload::ImageUpload.create(
        file_name: "image.jpg",
        file_type: "image/jpeg", file_size: 12345,
        source_url: "http://s3.amazonaws.com/vz-test-dropbox/image.jpg")
    end

    should delegate :ingestable, to: :ingest
    should "delegate :ingestable, to: :ingest" do
      @upload.ingest = FactoryGirl.create(:image_ingest, :ingestable_document)
      assert_equal @upload.ingest.ingestable, @upload.ingestable
    end

    should delegate :ingestable=, to: :ingest
    should "delegate :ingestable=, to: :ingest" do
      @upload.ingestable = FactoryGirl.create(:document_with_track)
      assert_equal @upload.ingest.ingestable, @upload.ingestable
      assert_equal true, @upload.save
      @upload = Upload::ImageUpload.find(@upload.id)
      assert_equal @upload.ingest.ingestable, @upload.ingestable
    end

    should delegate :ingestable_id, to: :ingest
    should delegate :ingestable_type, to: :ingest
    should "delegate :ingestable_id, :ingestable_type, to: :ingest" do
      @upload.ingest = FactoryGirl.create(:image_ingest, :ingestable_document)
      assert_equal @upload.ingest.ingestable_id, @upload.ingestable_id
      assert_equal @upload.ingest.ingestable_type, @upload.ingestable_type
    end

    should delegate :ingestable_id=, to: :ingest
    should delegate :ingestable_type=, to: :ingest
    should "delegate :ingestable_id=, :ingestable_type=, to: :ingest" do
      ingestable = FactoryGirl.create(:document_with_track)
      @upload.ingestable_id   = ingestable.id
      @upload.ingestable_type = ingestable.class.name
      assert_equal @upload.ingest.ingestable_id, @upload.ingestable_id
      assert_equal @upload.ingest.ingestable_type, @upload.ingestable_type
      assert_equal @upload.ingest.ingestable, @upload.ingestable
      assert_equal true, @upload.save
      @upload = Upload::ImageUpload.find(@upload.id)
      assert_equal ingestable, @upload.ingestable
    end
  end

  context "validations" do
    context "s3 upload" do
      setup do
        @upload = Upload::ImageUpload.create(source_url: "http://s3.amazonaws.com/vz-test-dropbox/image-test.jpeg")
      end

      should "validate_presence_of :file_name" do
        assert_equal false, @upload.valid?
        assert_equal ["can't be blank"], @upload.errors[:file_name]
      end
    end

    context "source upload" do
      should "validate valid image source_url" do
        stub_request(:get, "https://www.voyz.es/samples/test.jpg").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
          to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'image/jpeg'})

        upload = Upload::ImageUpload.new(source_url: "https://www.voyz.es/samples/test.jpg", ingestable: FactoryGirl.build(:document_with_track))
        assert_equal true, upload.valid?
      end

      should "not validate invalid file source" do
        stub_request(:get, "https://www.voyz.es/samples/test.abc").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
          to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'html/text'})

        upload = Upload::ImageUpload.new(source_url: "https://www.voyz.es/samples/test.abc")
        assert_equal false, upload.valid?
        assert_equal ["does not refer to a valid media or service"],
          upload.errors[:source_url]
      end

      should "not validate invalid URL" do
        upload = Upload::ImageUpload.new(source_url: "xyz")
        assert_equal false, upload.valid?
        assert_equal ["is invalid"], upload.errors[:source_url]
      end

      should "validate unresolvable URL" do
        stub_request(:get, "http://www.example.com/").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
          to_return(:status => 403, :body => "", :headers => {})
        upload = Upload::ImageUpload.new(source_url: "http://www.example.com")
        assert_equal false, upload.valid?
        assert_equal ["is not accessible access forbidden"], upload.errors[:source_url]
      end
    end
  end

  context "Model::S3" do
    setup do
      @upload = FactoryGirl.create(:image_upload, :ingestable)
    end

    should "#s3_bucket_name" do
      assert_equal "vz-test-assets-origin", @upload.s3_origin_bucket_name
    end

    should "#s3_origin_url" do
      assert_equal "http://s3.amazonaws.com/vz-test-assets-origin/#{@upload.ingest.uid}/#{@upload.ingest.handle}", @upload.s3_origin_url
    end

    context "#s3_origin_key" do
      should "be derived from uid and handle" do
        assert_equal "#{@upload.ingest.uid}/#{@upload.ingest.handle}", @upload.s3_origin_key
      end

      should "be derived from origin_url" do
        @upload.ingest.origin_url = "http://s3.amazonaws.com/vz-test-assets-origin/#{@upload.ingest.uid}/#{@upload.ingest.handle}"
        assert_equal "#{@upload.ingest.uid}/#{@upload.ingest.handle}", @upload.s3_origin_key
      end
    end
  end
end
