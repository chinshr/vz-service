require 'test_helper'

class Upload::MediaUploadTest < ActiveSupport::TestCase
  context "validations" do
    context "s3 upload" do
      setup do
        @upload = Upload::MediaUpload.create(source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio-test.m4a")
      end

      should "validate_presence_of :file_name" do
        assert_equal false, @upload.valid?
        assert_equal ["can't be blank"], @upload.errors[:file_name]
      end
    end

    context "source upload" do
      should "validate valid audio source_url" do
        stub_request(:get, "https://www.voyz.es/samples/genesis-1-1-en-us.m4a").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
          to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'audio/mpeg'})

        upload = Upload::MediaUpload.new(source_url: "https://www.voyz.es/samples/genesis-1-1-en-us.m4a")
        assert_equal true, upload.valid?
        assert_equal "Genesis 1 1 En Us", upload.title
      end

      should "validate valid accented source_url" do
        stub_request(:get, "http://www.radioagricultura.cl/wp-content/uploads/2016/01/FARO-ECON%C3%93MICO-JUEVES-28-ENERO-2016.mp3").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
          to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'audio/mpeg'})

        upload = Upload::MediaUpload.new(source_url: "http://www.radioagricultura.cl/wp-content/uploads/2016/01/FARO-ECONÓMICO-JUEVES-28-ENERO-2016.mp3")
        assert_equal true, upload.valid?
        assert_equal "Faro Económico Jueves 28 Enero 2016", upload.title
      end

      should "validate YouTube source" do
        stub_request(:get, "https://www.youtube.com/watch?v=aORId5oBmCM").
          with(:headers => {'Accept'=>'*/*'}).
          to_return(:status => 200, :body => '<html><head><title>Foo title</title><meta name="description" content="Bar description"><meta name="keywords" content="foo, bar, baz..., ..."></head></html>', :headers => {})
        upload = Upload::MediaUpload.new(source_url: "https://www.youtube.com/watch?v=aORId5oBmCM")
        assert_equal true, upload.valid?
        assert_equal true, upload.metadata.present?
        assert_equal true, upload.ingest.changes[:metadata].present?
        assert_equal true, upload.metadata['target'].present?
        assert_equal "youtube", upload.metadata['target']['ms_name']
        assert_equal "Foo Title", upload.title
        assert_equal "Bar description", upload.description
        assert_equal ["foo", "bar"], upload.tag_list
      end

      should "not validate invalid file source" do
        stub_request(:get, "https://www.voyz.es/samples/xyz.abc").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
          to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'html/text'})

        upload = Upload::MediaUpload.new(source_url: "https://www.voyz.es/samples/xyz.abc")
        assert_equal false, upload.valid?
        assert_equal ["does not refer to a valid media or service"],
          upload.errors[:source_url]
      end

      should "not validate invalid URL" do
        upload = Upload::MediaUpload.new(source_url: "xyz")
        assert_equal false, upload.valid?
        assert_equal ["is invalid"], upload.errors[:source_url]
      end

      should "validate unresolvable URL" do
        stub_request(:get, "http://www.example.com/").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
          to_return(:status => 403, :body => "", :headers => {})
        upload = Upload::MediaUpload.new(source_url: "http://www.example.com")
        assert_equal false, upload.valid?
        assert_equal ["is not accessible access forbidden"], upload.errors[:source_url]
      end
    end

    should "validate presence of title on update" do
      upload = Upload::MediaUpload.create(file_name: "audio-test.m4a", file_type: "audio/x-m4a",
        file_size: 12345, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio-test.m4a")
      assert_equal "Audio Test", upload.title
      upload.title = ""
      assert_equal false, upload.valid?
      assert_equal ["can't be blank"], upload.errors[:title]
    end
  end

  context "callbacks" do
    should "before_validation :set_metadata, on: :create" do
      upload = Upload::MediaUpload.new(file_name: "audio.m4a", file_type: "audio/x-m4a",
        file_size: 12345, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio.m4a")
      assert_equal true, upload.valid?
      assert_equal "Audio", upload.title
    end
  end

  context "scopes" do
    setup do
      @upload = FactoryGirl.create(:media_upload_as_audio)
    end

    should "#started" do
      assert_equal [], Upload::MediaUpload.started
      @upload.ingest.update_attribute(:aasm_state, "started")
      assert_equal [@upload], Upload::MediaUpload.started
    end

    should "#stopped" do
      assert_equal [], Upload::MediaUpload.stopped
      @upload.ingest.update_attribute(:aasm_state, "stopped")
      assert_equal [@upload], Upload::MediaUpload.stopped
    end

    should "#reset" do
      assert_equal [], Upload::MediaUpload.reset
      @upload.ingest.update_attribute(:aasm_state, "reset")
      assert_equal [@upload], Upload::MediaUpload.reset
    end

    should "#removed" do
      assert_equal [], Upload::MediaUpload.removed
      @upload.ingest.update_attribute(:aasm_state, "removed")
      assert_equal [@upload], Upload::MediaUpload.removed
    end

    should "#finished" do
      assert_equal [], Upload::MediaUpload.finished
      @upload.ingest.update_attribute(:aasm_state, "finished")
      assert_equal [@upload], Upload::MediaUpload.finished
    end

    should "#most_recent" do
      assert_equal [@upload], Upload::MediaUpload.most_recent
      assert_equal [@upload], Upload::MediaUpload.most_recent(1)
      assert_equal [], Upload::MediaUpload.most_recent(0)
    end
  end

  context "delegate" do
    setup do
      @upload = Upload::MediaUpload.create(file_name: "audio.m4a", file_type: "audio/x-m4a",
        file_size: 12345, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio.m4a")
    end

    should delegate :privacy, to: :ingest, allow_nil: true
    should delegate :privacy=, to: :ingest, allow_nil: true
    should "delegate :privacy" do
      @upload.privacy = "public"
      assert_equal ["public"], @upload.privacy
      assert_equal @upload.ingest.document.privacy, @upload.privacy
    end

    should "delegate :slug" do
      assert_equal @upload.ingest.document.slug, @upload.slug
    end

    should "delegate :slug_id" do
      assert_equal @upload.ingest.document.slug_id, @upload.slug_id
    end

    should delegate :title, to: :ingest, allow_nil: true
    should delegate :title=, to: :ingest, allow_nil: true

    should "delegate :title" do
      assert_equal @upload.ingest.document.title, @upload.title
    end

    should "delegate :title=" do
      @upload.title = "A new title"
      assert_equal "A new title", @upload.ingest.document.title
    end

    should delegate :description, to: :ingest, allow_nil: true
    should delegate :description=, to: :ingest, allow_nil: true

    should "delegate :description" do
      assert_equal @upload.ingest.document.description, @upload.description
    end

    should "delegate :description=" do
      @upload.description = "A new description"
      assert_equal "A new description", @upload.ingest.document.description
    end

    should delegate :tag_list, to: :ingest, allow_nil: true
    should delegate :tag_list=, to: :ingest, allow_nil: true

    should "delegate :tag_list" do
      assert_equal @upload.ingest.document.tag_list, @upload.tag_list
    end

    should "delegate :tag_list=" do
      @upload.tag_list = ["a", "new", "tag", "list"]
      assert_equal ["a", "new", "tag", "list"], @upload.ingest.document.tag_list
    end

    should delegate :locale, to: :ingest, allow_nil: true
    should delegate :locale=, to: :ingest, allow_nil: true

    should "delegate :locale" do
      assert_equal @upload.ingest.document.locale, @upload.locale
    end

    should "delegate :locale=" do
      @upload.locale = "it-IT"
      assert_equal "it-IT", @upload.ingest.document.locale
    end

    should delegate :use_source_annotations, to: :ingest, allow_nil: true
    should delegate :use_source_annotations=, to: :ingest, allow_nil: true

    should "delegate :use_source_annotations" do
      assert_equal @upload.ingest.use_source_annotations, @upload.use_source_annotations
    end

    should "delegate :use_source_annotations=" do
      @upload.use_source_annotations = true
      assert_equal true, @upload.ingest.use_source_annotations
    end

    should delegate :handle, to: :ingest, allow_nil: true
    should delegate :handle=, to: :ingest, allow_nil: true

    should "delegate :handle" do
      assert_equal @upload.ingest.handle, @upload.handle
    end

    should "delegate :handle=" do
      @upload.handle = "abcd1234"
      assert_equal "abcd1234", @upload.ingest.handle
    end
  end # context "delegate"

  should "humanize file name" do
    upload = Upload::MediaUpload.new(file_name: "i_like_pickles.m4a")
    upload.valid?
    assert_equal "I Like Pickles", upload.title
  end

  should "tell if locale has recently changed" do
    upload = FactoryGirl.create(:media_upload_as_audio, :source_url => "http://s3.amazonaws.com/vz-test-dropbox/61glI7mwmN")
    assert_equal false, upload.send(:has_locale_recently_changed?)
    upload.locale = "de-DE"
    assert_equal true, upload.send(:has_locale_recently_changed?)
  end

  context "#handle" do
    should "set handle if not S3 and not present" do
      upload = Upload::MediaUpload.new
      upload.valid?
      assert_equal 20, upload.handle.length
    end

    should "derive handle from S3 source URL" do
      upload = Upload::MediaUpload.new(source_url: "http://s3.amazonaws.com/vz-test-dropbox/61glI7mwmN")
      upload.valid?
      assert_equal "61glI7mwmN", upload.handle
    end

    should "use assigned handle" do
      upload = Upload::MediaUpload.new(handle: "abcd1234")
      upload.valid?
      assert_equal "abcd1234", upload.handle
    end
  end

  context "audio upload" do
    context "class" do
      should "#class_name_from_content_type_for" do
        assert_equal "Upload::MediaUpload", Upload.class_name_from_content_type_for("audio/mp3")
      end

      should "#accepted_file_type?" do
        assert_equal true, Upload::MediaUpload.accepted_file_type?("audio/x-m4a")
        assert_equal false, Upload::MediaUpload.accepted_file_type?("foo/bar")
      end

      should "build Upload::AudioUpload instance with :type" do
        assert_equal "Upload::MediaUpload", Upload.new(type: "Upload::MediaUpload").class.name
        assert_equal "Upload::MediaUpload", Upload.new(type: "media_upload").class.name
      end
    end

    context "validations" do
      should "validate audio file_type" do
        upload = FactoryGirl.build :media_upload_as_audio, file_type: "audio/x-m4a"
        assert upload.valid?, "should be valid"
        assert_equal [], upload.errors[:file_type]
      end

      should "not validate file_type other than audio" do
        upload = FactoryGirl.build :media_upload_as_audio, file_type: "XXX"
        assert_equal false, upload.valid?, "should not be valid"
        assert_equal [I18n.t("activerecord.errors.models.upload.attributes.file_type.media_expected")], upload.errors[:file_type]
      end
    end

    should "start ingest after s3 source_url is supplied" do
      upload = Upload::MediaUpload.new(file_name: "audio-test.m4a", file_type: "audio/x-m4a",
        file_size: 12345, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio-test.m4a")
      upload.save
      assert_equal :starting, upload.ingest.state
    end

    should "start restart after locale has changed" do
      upload = Upload::MediaUpload.new(file_name: "audio-test.m4a", file_type: "audio/x-m4a",
        file_size: 12345, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio-test.m4a", :locale => "en-US")

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
      upload = FactoryGirl.create(:media_upload_as_audio)
      assert upload.valid?, "should be true"
    end

    should "associated document have slug" do
      upload = FactoryGirl.create(:media_upload_as_audio)
      assert_equal upload.ingest.document.slug, upload.slug
    end

    should "build with default locale" do
      upload = FactoryGirl.create(:media_upload_as_audio)
      assert_equal "en-US", upload.locale
      assert_equal upload.ingest.document.locale, upload.locale
    end

    should "create audio ingest and document for audio upload" do
      upload = Upload::MediaUpload.create(file_name: "audio.m4a", file_type: "audio/x-m4a",
        file_size: 12345, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio.m4a")
      assert upload.ingest
      assert_equal Ingest::MediaIngest, upload.ingest.class
      assert_not_nil upload.ingest.document
      assert_equal Document, upload.ingest.document.class
    end

  end  # audio upload

  context "video upload" do
    context "class" do
      should "#class_name_from_content_type_for" do
        assert_equal "Upload::MediaUpload", Upload.class_name_from_content_type_for("video/mp4")
      end

      should "#accepted_file_type?" do
        assert_equal true, Upload::MediaUpload.accepted_file_type?("video/mp4")
        assert_equal false, Upload::MediaUpload.accepted_file_type?("foo/bar")
      end
    end

    context "validations" do
      should validate_presence_of :type

      should "validate video file_type" do
        upload = Upload::MediaUpload.new(file_name: "video-test.mp4", file_type: "video/mp4",
          file_size: 123456, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio-test.m4a")
        assert_equal true, upload.valid?
        assert_equal [], upload.errors[:file_type]
      end
    end

    should "start ingest after s3 source_url is supplied" do
      upload = Upload::MediaUpload.new(file_name: "video-test.mp4", file_type: "video/mp4",
        file_size: 12345, source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio-test.m4a")
      assert_equal true, upload.valid?
      assert_equal true, upload.is_a?(Upload::MediaUpload)
      upload.save
      assert_equal :starting, upload.ingest.state
    end

    should "create video ingest and document for audio upload" do
      upload = Upload::MediaUpload.create(file_name: "video.mp4", file_type: "video/mp4",
        file_size: 1234567, source_url: "http://s3.amazonaws.com/vz-test-dropbox/video.mp4")
      assert_equal true, upload.valid?
      assert_not_nil upload.ingest
      assert_equal "Ingest::MediaIngest", upload.ingest.class.name
      assert_not_nil upload.ingest.document
      assert_equal "Document", upload.ingest.document.class.name
    end

    should "associated document have slug" do
      upload = FactoryGirl.create(:media_upload_as_video)
      assert_equal upload.ingest.document.slug, upload.slug
    end

    should "build with default locale" do
      upload = FactoryGirl.create(:media_upload_as_video)
      assert_equal "en-US", upload.locale
      assert_equal upload.ingest.document.locale, upload.locale
    end
  end  # video upload
end