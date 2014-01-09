require 'test_helper'

class Ingest::AudioTest < ActiveSupport::TestCase

  should "delegate to document getters" do
    document = FactoryGirl.create(:document)
    ingest = FactoryGirl.create(:ingest_audio, :ingestable => document)
    assert_equal document.title, ingest.title
    assert_equal document.description, ingest.description
  end

  should "delegate to document setters" do
    document = FactoryGirl.create(:document)
    ingest = FactoryGirl.create(:ingest_audio, :ingestable => document)
    ingest.title = "Wizard of Oz!"
    ingest.description = "The wonderful Wizard of Oz!"
    assert_equal document.title, ingest.title
    assert_equal document.description, ingest.description
  end
end
