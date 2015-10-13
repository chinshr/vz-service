require 'test_helper'
require "#{Rails.root}/app/models/ingest/process"

class Ingest::ProcessTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :ingest
    should belong_to :server
  end

  should "create process" do
    assert_difference "Ingest::Process.count", 1 do
      Ingest::Process.create(ingest: FactoryGirl.create(:ingest_audio), server: FactoryGirl.create(:cpw_ingest_server))
    end
  end

  should "not create duplicate process" do
    assert_difference "Ingest::Process.count", 1 do
      ingest = FactoryGirl.create(:ingest_audio)
      server = FactoryGirl.create(:cpw_ingest_server)
      Ingest::Process.create(ingest: ingest, server: server)
      assert_raise ActiveRecord::RecordNotUnique do
        Ingest::Process.create(ingest: ingest, server: server)
      end
    end
  end
end
