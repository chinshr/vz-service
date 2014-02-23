require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :sender
    should have_many :attachments
  end

  should "convert html to text" do
    m = Message.create(html: "<i>I like pickles</i>")
    assert_equal "I like pickles", m.text
  end
  
  should "infer locale from message text" do
    m = Message.new(subject: "New Recording")
    assert_equal "en", m.locale

    m = Message.new(subject: "Das ist eine Audio", html: "<i>Aufzeichnung</i>")
    assert_equal "de", m.locale

    m = Message.new(subject: "Grabación de audio", text: "")
    assert_equal "es", m.locale
  end
  
  should "attach upload as attachment" do
    message = FactoryGirl.create(:message)
    upload  = FactoryGirl.build(:upload_audio)
    assert_difference "Upload.count", 1 do
      assert_difference "Attaching.count", 1 do
        message.attachments << upload
      end
    end
    assert_equal upload, message.attachments.first
  end
  
  should "have valid attachments" do
    message = FactoryGirl.create(:message)
    assert_difference "Upload.count", 1 do
      assert_difference "Attaching.count", 1 do
        message.attachments.build FactoryGirl.attributes_for(:upload_audio).merge(type: "audio")
        assert_equal true, message.valid_attachments?
        message.save!
      end
    end
  end
  
  should "not have valid attachments" do
    message = FactoryGirl.create(:message)
    assert_difference "Upload.count", 1 do
      assert_difference "Attaching.count", 1 do
        message.attachments.build FactoryGirl.attributes_for(:upload_audio).merge(type: "audio")
        assert_equal true, message.save
        message.attachments.build FactoryGirl.attributes_for(:upload_audio).merge(type: "audio").merge(file_type: "mux/pux")
        assert_equal false, message.valid_attachments?
        assert_equal false, message.valid?
        assert_equal ["Attachments is invalid"], message.errors.full_messages
        assert_equal false, message.save
      end
    end
  end
end
