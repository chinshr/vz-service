require 'test_helper'

class Ingest::Server::StopJobTest < ActiveSupport::TestCase

  should "stop instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    Ingest::Server.any_instance.expects(:_stop).returns(true)
    Ingest::Server::StopJob.new.perform(server.id)
  end

end