require 'test_helper'

class Upload::AudioUploadTest < ActiveSupport::TestCase
  context "class" do
    should "#class_name_from_content_type_for" do
      assert_equal "Upload::AudioUpload", Upload.class_name_from_content_type_for("audio/mp3")
    end

    should "#accepted_file_type?" do
      assert_equal true, Upload::AudioUpload.accepted_file_type?("audio/x-m4a")
      assert_equal false, Upload::AudioUpload.accepted_file_type?("foo/bar")
    end

    should "build Upload::AudioUpload instance with :type" do
      assert_equal "Upload::AudioUpload", Upload.new(type: "Upload::AudioUpload").class.name
      assert_equal "Upload::AudioUpload", Upload.new(type: "audio_upload").class.name
      assert_equal "Upload::AudioUpload", Upload.new(type: :"audio").class.name
    end
  end

  context "validations" do
    should validate_presence_of :type

    should "validate audio file_type" do
      upload = FactoryGirl.build :upload_audio, file_type: "audio/x-m4a"
      assert upload.valid?, "should be valid"
      assert_equal [], upload.errors[:file_type]
    end

    should "not validate file_type other than audio" do
      upload = FactoryGirl.build :upload_audio, file_type: "XXX"
      assert_equal false, upload.valid?, "should not be valid"
      assert_equal [I18n.t("activerecord.errors.models.upload.attributes.file_type.audio_expected")], upload.errors[:file_type]
    end
  end

  should "start ingest after s3_url is supplied" do
    upload = Upload.new(type: "audio", file_name: "audio-test.m4a", file_type: "audio/x-m4a",
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a")
    upload.save
    assert_equal :starting, upload.ingest.state
  end

  should "start restart after locale has changed" do
    upload = Upload.new(type: "audio", file_name: "audio-test.m4a", file_type: "audio/x-m4a",
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a", :locale => "en-US")

    # saving upload should trigger start!
    upload.save
    assert_equal :starting, upload.ingest.state
    upload.ingest.process!  # happens inside worker
    assert_equal :started, upload.ingest.state

    # changing upload locale should trigger restart!
    upload.locale = "es-ES"
    upload.save
    assert_equal :restarting, upload.ingest.state
    upload.ingest.process!  # happens inside worker
    assert_equal :started, upload.ingest.state
  end

  should "create" do
    upload = FactoryGirl.create(:upload_audio)
    assert upload.valid?, "should be true"
  end

  should "associated document have slug" do
    upload = FactoryGirl.create(:upload_audio)
    assert_equal upload.ingest.document.slug, upload.slug
  end

  should "build with default locale" do
    upload = FactoryGirl.create(:upload_audio)
    assert_equal "en-US", upload.locale
    assert_equal upload.ingest.document.locale, upload.locale
  end

  should "create audio ingest and document for audio upload" do
    upload = Upload.create(type: "audio", file_name: "audio.m4a", file_type: "audio/x-m4a",
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio.m4a")
    assert upload.ingest
    assert_equal ::Ingest::AudioIngest, upload.ingest.class
    assert_not_nil upload.ingest.document
    assert_equal ::Document, upload.ingest.document.class
    assert_equal upload.ingest.title, upload.humanized_file_name
  end
end