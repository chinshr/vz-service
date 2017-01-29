require 'test_helper'

class EmailProcessorTest < ActiveSupport::TestCase
  setup do
    EmailProcessor.stubs(:upload_file_to_s3_bucket).returns(true)
    Ingest::Server::RestartJob.stubs(:perform_later).returns(true)
    ActionMailer::Base.deliveries.clear
    @email = mock('email')
    @email.stubs(:attachments).returns([])
    @email.stubs(:subject).returns(nil)
    @email.stubs(:body).returns(nil)
    @email.stubs(:from).returns(nil)
  end

  context "process_source_urls" do
    setup do
      @params = {
        "dkim"=>"none",
        "envelope"=>{"to"=>["my@app.example.com"], "from"=>"raj@example.com"},
        "to"=>"my@app.example.com", "from"=>"Raj Aakula <raj@example.com>", "sender_ip"=>"199.36.142.181",
        "subject"=>"Sample recording 1",
        "attachment-info"=>"{\"attachment1\":{\"filename\":\"sample.m4a\",\"name\":\"sample.m4a\",\"type\":\"audio/x-m4a\"}}",
        "charsets"=>"{\"to\":\"UTF-8\",\"subject\":\"UTF-8\",\"from\":\"UTF-8\"}",
        "headers"=>"Received: by mx-006.sjc1.sendgrid.net with ..."
      }
    end

    should "not have any source urls" do
      assert_equal [], EmailProcessor.new(@email).send(:source_urls)
      assert_equal false, EmailProcessor.new(@email).send(:has_source_urls?)
    end

    should "process message with source url" do
      stub_request(:get, "http://www.voyz.es/samples/genesis-1-1-en-us.m4a").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
        to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'audio/mpeg'})
      url = "http://www.voyz.es/samples/genesis-1-1-en-us.m4a"
      subject = "Check this #{url}"
      assert_difference "User.count", 1 do
        assert_difference "Message.count", 1 do
          assert_difference "Upload.count", 1 do
            assert_enqueued_with(job: ActionMailer::DeliveryJob) do
              normalized_params(params({subject: subject, text: "{:-O}"})).each do |p|
                Griddler::Email.new(p).process
              end
            end
          end
        end
      end
      message, upload = Message.last, Upload.last
      assert_equal User.last, message.sender
      assert_equal User.last, Upload.last.user
      assert_equal url, upload.source_url
      assert_equal upload, message.attachments.first
      assert_equal true, upload.use_source_annotations
    end

    should "not process without source url" do
      assert_difference "User.count", 0 do
        assert_difference "Message.count", 0 do
          assert_difference "Upload.count", 0 do
            normalized_params(@params).each do |p|
              Griddler::Email.new(p).process
            end
          end
        end
      end
    end

    should "not process malformed source urls" do
      assert_difference "User.count", 0 do
        assert_difference "Message.count", 0 do
          assert_difference "Upload.count", 0 do
            normalized_params(params(subject: "www.example.com/sample.mp4")).each do |p|
              Griddler::Email.new(p).process
            end
          end
        end
      end
    end

    should "process message with source url in body" do
      stub_request(:get, "https://www.youtube.com/watch?v=aORId5oBmCM").
        with(:headers => {'Accept'=>'*/*'}).
        to_return(:status => 200, :body => '<html><head><title>Foo title</title><meta name="description" content="Bar description"><meta name="keywords" content="foo, bar, baz..., ..."></head></html>', :headers => {})
      stub_request(:get, "https://www.vimeo.com/161138879").
        with(:headers => {'Accept'=>'*/*'}).
        to_return(:status => 200, :body => '<html><head><title>Foo title</title><meta name="description" content="Bar description"><meta name="keywords" content="foo, bar, baz..., ..."></head></html>', :headers => {})

      url1 = "https://www.youtube.com/watch?v=aORId5oBmCM"
      url2 = "https://www.vimeo.com/161138879"
      body = "Check this #{url1} that I found inside #{url2}."
      assert_difference "User.count", 1 do
        assert_difference "Message.count", 1 do
          assert_difference "Upload.count", 2 do
            assert_enqueued_with(job: ActionMailer::DeliveryJob) do
              normalized_params(params({text: body})).each do |p|
                Griddler::Email.new(p).process
              end
            end
          end
        end
      end
      assert_equal [url2, url1], Upload.order(created_at: :desc).limit(2).map(&:source_url)
      assert_equal false, Upload.last.use_source_annotations
    end
  end

  context "process_attachments" do
    setup do
      attachment1 = ActionDispatch::Http::UploadedFile.new({
        :filename     => "sample.m4a",
        :content_type => "audio/x-m4a",
        :tempfile     => File.new("#{Rails.root}/test/fixtures/sample.m4a")
      })

      @params = {
        "dkim"=>"none",
        "envelope"=>{"to"=>["my@app.example.com"], "from"=>"raj@example.com"},
        "to"=>"my@app.example.com", "from"=>"Raj Aakula <raj@example.com>", "sender_ip"=>"199.36.142.181",
        "subject"=>"Sample recording 1",
        "attachment-info"=>"{\"attachment1\":{\"filename\":\"sample.m4a\",\"name\":\"sample.m4a\",\"type\":\"audio/x-m4a\"}}",
        "charsets"=>"{\"to\":\"UTF-8\",\"subject\":\"UTF-8\",\"from\":\"UTF-8\"}",
        "headers"=>"Received: by mx-006.sjc1.sendgrid.net with ...",
        "attachment1"=>attachment1, "attachments"=>"1", "html" => "<i>Check this out!</i>"
      }
    end

    unless ENV["CI_CODESHIP"]
      # does not run on CodeShip CI due to mime type detection
      should "process message with attachments, signup user and send notifications" do
        assert_difference "User.count", 1 do
          assert_difference "Message.count", 1 do
            assert_difference "Upload.count", 1 do
              assert_enqueued_with(job: ActionMailer::DeliveryJob) do
                normalized_params(@params).each do |p|
                  Griddler::Email.new(p).process
                end
              end
            end
          end
        end
        assert_equal User.last, Message.last.sender
        assert_equal User.last, Upload.last.user
      end

      should "humanize audio file as upload title if no subject given" do
        @params.delete(:subject)
        normalized_params(@params).each do |p|
          Griddler::Email.new(p).process
        end
        assert_equal "Sample Recording 1", Upload::MediaUpload.last.title
      end

      context "determine locale from sender's email address" do
        should "default to en-US" do
          @params["to"] = "my@app.example.com"
          normalized_params(@params).each do |p|
            Griddler::Email.new(p).process
          end
          assert_equal "en-US", Upload::MediaUpload.last.locale
        end

        should "my+es to es-ES" do
          @params["to"] = "my+es@app.example.com"
          normalized_params(@params).each do |p|
            Griddler::Email.new(p).process
          end
          assert_equal "es-ES", Upload::MediaUpload.last.locale
        end

        should "en-UK" do
          @params["to"] = "my+en-uk@app.example.com"
          normalized_params(@params).each do |p|
            Griddler::Email.new(p).process
          end
          assert_equal "en-UK", Upload::MediaUpload.last.locale
        end
      end

      should "process message with attachments, send notification" do
        FactoryGirl.create(:user, :email => "raj@example.com")
        ActionMailer::Base.deliveries.clear

        perform_enqueued_jobs do

          assert_difference "User.count", 0 do
            assert_difference "Message.count", 1 do
              assert_difference "Upload.count", 1 do
                assert_difference "ActionMailer::Base.deliveries.size", 1 do
                  normalized_params(@params).each do |p|
                    Griddler::Email.new(p).process
                  end
                end
              end
            end
          end

        end
      end

      should "not process message without any attachment and not send any notifications" do
        assert_difference "User.count", 0 do
          assert_difference "Message.count", 0 do
            assert_difference "Upload.count", 0 do
              assert_difference "ActionMailer::Base.deliveries.size", 0 do
                normalized_params({
                  "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Forgot attachments",
                  "text" => "Umm, I must have forgotten something!?"
                }).each do |p|
                  Griddler::Email.new(p).process
                end
              end
            end
          end
        end
      end

      should "ignore text attachments and upload audio files and send valid message notification" do
        attachment1 = ActionDispatch::Http::UploadedFile.new({
          :filename     => "sample.m4a",
          :content_type => "invalid/content-type",
          :tempfile     => File.new("#{Rails.root}/test/fixtures/sample.m4a")
        })
        # attachment1.content_type = "audio/x-m4a"  # re-assign, doesn't work otherwise!

        attachment2 = ActionDispatch::Http::UploadedFile.new({
          :filename     => "msg-1483-73.txt",
          :content_type => "text/plain",
          :tempfile     => File.new("#{Rails.root}/test/fixtures/msg-1483-73.txt")
        })
        # attachment2.content_type = "text/plain"  # re-assign, doesn't work otherwise!


        assert_difference "User.count", 1 do
          assert_difference "Message.count", 1 do
            assert_difference "Upload.count", 1 do
              assert_enqueued_with(job: ActionMailer::DeliveryJob) do
                normalized_params({"format" => "xml", "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Wrong content type",
                  "html" => "<i>Double check audio file!</i>", "attachments" => "2",
                  "attachment1" => attachment1, "attachment2" => attachment2
                }).each do |p|
                  Griddler::Email.new(p).process
                end
              end
            end
          end
        end

        # assert_equal "We are working hard transcribing your message.", ActionMailer::Base.deliveries[1].subject
      end

      should "not process with invalid audio file and send invalid message notification" do
        attachement1 = ActionDispatch::Http::UploadedFile.new({
          :filename     => "sample.m4a",
          :content_type => "invalid/content-type",
          :tempfile     => File.new("#{Rails.root}/test/fixtures/msg-1483-73.txt")
        })

        assert_difference "User.count", 0 do
          assert_difference "Message.count", 0 do
            assert_difference "Upload.count", 0 do
              assert_difference "ActionMailer::Base.deliveries.size", 0 do
                normalized_params({
                  "format" => "xml", "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Wrong content type",
                  "html" => "<i>Double check audio file!</i>", "attachments" => "1", "attachment1" => attachement1
                }).each do |p|
                  Griddler::Email.new(p).process
                end
              end
            end
          end
        end
      end

    end
  end

  context "#extract_locale" do
    should "directive wins over email ecoding" do
      @email.stubs(:to).returns([{email: "my+es@voyz.es"}])
      @email.stubs(:body).returns("{de}")
      assert_equal "de-DE", EmailProcessor.new(@email).send(:extract_locale)
    end

    should "use email ecoding" do
      @email.stubs(:to).returns([{email: "my+es@voyz.es"}])
      assert_equal "es-ES", EmailProcessor.new(@email).send(:extract_locale)
    end

    should "default" do
      @email.stubs(:to).returns([{email: "my@voyz.es"}])
      assert_equal "en-US", EmailProcessor.new(@email).send(:extract_locale)
    end
  end

  should "extract locale from email addresses" do
    assert_equal "en-US", EmailProcessor.new(@email).send(:extract_locale_from_email_address, [{email: "my+en@voyz.es"}])
    assert_equal "en-US", EmailProcessor.new(@email).send(:extract_locale_from_email_address, [{email: "my+en_US@voyz.es"}])
    assert_equal "es-ES", EmailProcessor.new(@email).send(:extract_locale_from_email_address, [{email: "my+es@voyz.es"}])
    assert_nil EmailProcessor.new(@email).send(:extract_locale_from_email_address, [{email: "my@voyz.es"}])
    assert_nil EmailProcessor.new(@email).send(:extract_locale_from_email_address, nil)
    assert_nil EmailProcessor.new(@email).send(:extract_locale_from_email_address, [])
  end

  context "extract locale from directive" do
    should "{en-US} -> en-US" do
      @email.stubs(:body).returns("{en-US}")
      assert_equal "en-US", EmailProcessor.new(@email).send(:extract_locale_from_directive)
    end

    should "{en} -> en-US" do
      @email.stubs(:body).returns("{en}")
      assert_equal "en-US", EmailProcessor.new(@email).send(:extract_locale_from_directive)
    end

    should "{en_us} -> en-US" do
      @email.stubs(:body).returns("{en_us}")
      assert_equal "en-US", EmailProcessor.new(@email).send(:extract_locale_from_directive)
    end

    should "{es} -> es-ES" do
      @email.stubs(:body).returns("{es}")
      assert_equal "es-ES", EmailProcessor.new(@email).send(:extract_locale_from_directive)
    end

    should "{de} -> de-DE" do
      @email.stubs(:subject).returns("{de}")
      assert_equal "de-DE", EmailProcessor.new(@email).send(:extract_locale_from_directive)
    end

    should "{d} -> nil" do
      @email.stubs(:body).returns("{d}")
      assert_nil EmailProcessor.new(@email).send(:extract_locale_from_directive)
    end

    should "{aufbauen-usbekistan} -> nil" do
      @email.stubs(:body).returns("{aufbauen-usbekistan}")
      assert_nil EmailProcessor.new(@email).send(:extract_locale_from_directive)
    end
  end

  context "#extract_use_source_annotations" do
    should "{:-o} -> true" do
      @email.stubs(:body).returns("{:-o}")
      assert_equal true, EmailProcessor.new(@email).send(:extract_use_source_annotations)
    end

    should "{:-O} -> true" do
      @email.stubs(:body).returns("{:-O}")
      assert_equal true, EmailProcessor.new(@email).send(:extract_use_source_annotations)
    end

    should "{:-/} -> false" do
      @email.stubs(:body).returns("{:-/}")
      assert_equal false, EmailProcessor.new(@email).send(:extract_use_source_annotations)
    end

    should "default -> false" do
      assert_equal false, EmailProcessor.new(@email).send(:extract_use_source_annotations)
    end
  end

  protected

  def normalized_params(params)
    params = ActionController::Parameters.new(params)
    Array.wrap(Griddler.configuration.email_service.normalize_params(params))
  end

  def params(options = {})
    @params.merge(options.stringify_keys)
  end
end