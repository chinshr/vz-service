require 'test_helper'

class SegmentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :document
    should belong_to :track
    should belong_to :ingest
    should belong_to :chunk
  end
end
