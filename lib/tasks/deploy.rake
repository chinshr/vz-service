namespace :deploy do
  namespace :after do

    namespace :ingest do
      desc 'Upgrade ingest stage machine'
      task :rename_ingest_stages => :environment do
        def execute(sql); ActiveRecord::Base.connection.execute(sql); end

        # append _stage
        execute "UPDATE ingests SET aasm_stage = 'begin_stage' WHERE ingests.aasm_stage = 'start'"
        execute "UPDATE ingests SET aasm_stage = 'harvest_stage' WHERE ingests.aasm_stage = 'harvest'"
        execute "UPDATE ingests SET aasm_stage = 'transcode_stage' WHERE ingests.aasm_stage = 'transcode'"
        execute "UPDATE ingests SET aasm_stage = 'split_stage' WHERE ingests.aasm_stage = 'split'"
        execute "UPDATE ingests SET aasm_stage = 'end_stage' WHERE ingests.aasm_stage = 'finish'"

        # remove stage
        execute "UPDATE ingests SET aasm_stage = NULL WHERE ingests.aasm_stage = 'crowdout'"
      end

      desc 'Set handle derived from source URL'
      task :set_handle => :environment do
        Ingest::MediaIngest.find_each do |ingest|
          if ingest.handle.blank?
            ingest.send :set_handle
            ingest.save if ingest.changed?
          end
        end
      end
    end

  end
end