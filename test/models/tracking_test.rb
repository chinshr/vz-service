require 'test_helper'

class TrackingTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :document
    should belong_to :track
    should belong_to :ingest
  end

  context "validations" do
    should validate_presence_of :document
    should validate_presence_of :track
  end
end
