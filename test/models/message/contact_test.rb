require 'test_helper'

class Message::ContactTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end

  context "validations" do
    should validate_presence_of :from
    should allow_value("test@example.com").for(:from)
    should validate_presence_of :body
    should validate_presence_of :sender_name
  end

  context "mailer" do
    should "deliver email" do
      assert_enqueued_with(job: ActionMailer::DeliveryJob) do
        @contact = FactoryGirl.create(:contact_message)
      end
    end
  end
end
