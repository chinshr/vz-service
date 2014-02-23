require 'test_helper'

class Upload::AudioTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of :type

    should "validate file_type audio" do
      upload = FactoryGirl.build :upload_audio, file_type: "audio/x-m4a"
      assert upload.valid?, "should be valid"
      assert_equal [], upload.errors[:file_type]
    end

    should "not validate file_type other than audio" do
      upload = FactoryGirl.build :upload_audio, file_type: "XXX"
      assert_equal false, upload.valid?, "should not be valid"
      assert_equal [I18n.t("activerecord.errors.models.upload.attributes.file_type.audio_expected")], upload.errors[:file_type]
    end
    
    should "validate presence of title on update" do
      upload = Upload.create(type: "audio", file_name: "audio-test.m4a", file_type: "audio/x-m4a", 
        file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a")
      assert_equal upload.humanized_file_name, upload.title
      upload.title = ""
      assert_equal false, upload.valid?
      assert_equal ["can't be blank"], upload.errors[:title]
    end
    
  end

  should "start ingest after s3_url is supplied" do
    Ingest::AudioWorker.jobs.clear
    upload = Upload.new(type: "audio", file_name: "audio-test.m4a", file_type: "audio/x-m4a", 
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a")
    assert_difference "Ingest::AudioWorker.jobs.size", 1 do
      upload.save
      assert_equal :starting, upload.ingest.state
    end
  end

  should "start restart after locale has changed" do
    Ingest::AudioWorker.jobs.clear
    upload = Upload.new(type: "audio", file_name: "audio-test.m4a", file_type: "audio/x-m4a", 
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a", :locale => "en-US")
    assert_difference "Ingest::AudioWorker.jobs.size", 2 do
      upload.save
      assert_equal :starting, upload.ingest.state
      upload.ingest.process!
      assert_equal :started, upload.ingest.state
      upload.locale = "es-ES"
      upload.save
      assert_equal :restarting, upload.ingest.state
    end
  end

  should "create" do
    upload = FactoryGirl.create(:upload_audio)
    assert upload.valid?, "should be true"
  end

  should "have slug" do
    upload = FactoryGirl.create(:upload_audio)
    assert_equal upload.ingest.ingestable.slug, upload.slug
  end

  should "build with default locale" do
    upload = FactoryGirl.create(:upload_audio)
    assert_equal "en-US", upload.locale
    assert_equal upload.ingest.ingestable.locale, upload.locale
  end

  should "build with default privacy" do
    upload = FactoryGirl.build(:upload_audio)
    assert_equal [:public], upload.privacy
    assert_equal upload.ingest.ingestable.privacy, upload.privacy
  end

  should "build Upload::Audio" do
    audio_upload = Upload.new type: "audio"
    assert audio_upload.is_a?(Upload::Audio), "should instantiate with :type parameter"
  end
  
  should "create audio ingest and document for audio upload" do
    upload = Upload.create(type: "audio", file_name: "audio.m4a", file_type: "audio/x-m4a", 
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio.m4a")
    assert upload.ingest
    assert upload.ingest.ingestable
    assert_equal upload.ingest.title, upload.humanized_file_name
  end
  
  should "have user" do
    upload = Upload.create(type: "audio", file_name: "audio.m4a", file_type: "audio/x-m4a", 
      file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio.m4a")
    user = FactoryGirl.create(:user)
    upload.user = user
    assert_equal true, upload.save
    upload = Upload.find_by_id(upload.id)
    assert_equal user, upload.user
  end

end
