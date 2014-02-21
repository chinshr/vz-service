require 'test_helper'

class Message::InboundTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :user
  end

  context "validations" do
    should validate_presence_of :user
  end
end
