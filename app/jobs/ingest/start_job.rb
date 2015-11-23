class Ingest::StartJob < ActiveJob::Base
  queue_as :default

  def perform(ingest_id)
    if @ingest = Ingest.find(ingest_id)
      unless @server = Ingest::Server::CPWServer.available.first
        # create new instance from image and launch
        @instance = Provider::AWS::EC2.new.launch(type: "cpw")
        @server   = Ingest::Server::CPWServer.create_from(@instance)
      end
      @server.with_lock do
        # restart instance in case it was stopped
        if @server.restart
          @server.ingests << @ingest
        end
      end
    end
  end
end