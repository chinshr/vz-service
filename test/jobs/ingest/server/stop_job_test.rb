require 'test_helper'

class Ingest::Server::StopJobTest < ActiveSupport::TestCase

  should "stop instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    Ingest::Server.any_instance.expects(:_stop).returns(true)
    Ingest::Server::StopJob.new.perform(server.id)
  end

  should "not stop instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    worker = FactoryGirl.create(:ingest_worker, server: server)
    Ingest::Server.any_instance.expects(:_stop).never
    Ingest::Server::StopJob.new.perform(server.id)
  end

  should "stop instance without busy workers" do
    server = FactoryGirl.create(:cpw_ingest_server)
    worker1 = FactoryGirl.create(:ingest_worker, server: server, aasm_state: "stopped")
    worker2 = FactoryGirl.create(:ingest_worker, server: server, aasm_state: "finished")
    Ingest::Server.any_instance.expects(:_stop).returns(true)
    Ingest::Server::StopJob.new.perform(server.id)
  end

end