require 'test_helper'

class Upload::VideoUploadTest < ActiveSupport::TestCase
  context "class" do
    should "#class_name_from_file_type_for" do
      assert_equal "Upload::VideoUpload", Upload.class_name_from_file_type_for("video/mp4")
    end

    should "#accepted_file_type?" do
      assert_equal true, Upload::VideoUpload.accepted_file_type?("video/mp4")
      assert_equal false, Upload::VideoUpload.accepted_file_type?("foo/bar")
    end

    should "build Upload::VideoUpload instance with :type" do
      assert_equal "Upload::VideoUpload", Upload.new(type: "Upload::VideoUpload").class.name
      assert_equal "Upload::VideoUpload", Upload.new(type: "video_upload").class.name
      assert_equal "Upload::VideoUpload", Upload.new(type: :"video").class.name
    end
  end

  context "validations" do
    should validate_presence_of :type

    should "validate video file_type" do
      upload = Upload.new(type: "video", file_name: "video-test.mp4", file_type: "video/mp4",
        file_size: 123456, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a")
      assert_equal true, upload.valid?
      assert_equal [], upload.errors[:file_type]
    end

    should "not validate file_type other than video" do
      upload = Upload.new(type: "video", file_name: "video-test.mp4", file_type: "audio/mp3",
        file_size: 123456, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a")
      assert_equal false, upload.valid?
      assert_equal [I18n.t("activerecord.errors.models.upload.attributes.file_type.video_expected")], upload.errors[:file_type]
    end
  end

  should "start ingest after s3_url is supplied" do
    upload = Upload.new(type: "video", file_name: "video-test.mp4", file_type: "video/mp4",
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a")
    assert_equal true, upload.valid?
    assert_equal true, upload.is_a?(Upload::VideoUpload)
    upload.save
    assert_equal :starting, upload.ingest.state
  end

  should "create video ingest and document for audio upload" do
    upload = Upload.create(type: "video", file_name: "video.mp4", file_type: "video/mp4",
      file_size: 1234567, s3_url: "http://s3.amazonaws.com/dropbox/video.mp4")
    assert_equal true, upload.valid?
    assert_not_nil upload.ingest
    assert_equal "Ingest::VideoIngest", upload.ingest.class.name
    assert_not_nil upload.ingest.document
    assert_equal "Document", upload.ingest.document.class.name
    assert_equal upload.ingest.title, upload.humanized_file_name
  end

  should "associated document have slug" do
    upload = FactoryGirl.create(:upload_video)
    assert_equal upload.ingest.document.slug, upload.slug
  end

  should "build with default locale" do
    upload = FactoryGirl.create(:upload_video)
    assert_equal "en-US", upload.locale
    assert_equal upload.ingest.document.locale, upload.locale
  end
end