require 'test_helper'

class SessionTest < ActiveSupport::TestCase
  context "associations" do
    should have_many :uploads
  end

  context "validations" do
    should validate_uniqueness_of :uid
  end
end
