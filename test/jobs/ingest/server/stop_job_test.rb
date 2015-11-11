require 'test_helper'

class Ingest::Server::StopJobTest < ActiveSupport::TestCase

  should "stop instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    Ingest::Server.any_instance.expects(:_stop).returns(true)
    Ingest::Server::StopJob.new.perform(server.id)
  end

  should "not stop instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    server.ingests << FactoryGirl.create(:ingest_audio)
    Ingest::Server.any_instance.expects(:_stop).never
    Ingest::Server::StopJob.new.perform(server.id)
  end

end