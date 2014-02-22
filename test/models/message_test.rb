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
    upload  = FactoryGirl.create(:upload_audio)
    assert_difference "Attaching.count", 1 do
      message.attachments << upload
    end
    assert_equal upload, message.attachments.first
  end
  
  should "have valid attachments" do
    message = FactoryGirl.create(:message)
    message.attachments << FactoryGirl.create(:upload_audio)
    assert_equal true, message.valid_attachments?
  end
  
end
