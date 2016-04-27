namespace :deploy do
  namespace :after do

    namespace :image do
      desc 'Set image_format attributes for denorm'
      task :set_image_format_attributes => :environment do
        Image.where("images.width IS NULL AND images.height IS NULL AND images.format IS NULL AND images.aspect_ratio IS NULL").find_each do |image|
          image.width        = image.image_format.width
          image.height       = image.image_format.height
          image.format       = image.image_format.format
          image.aspect_ratio = image.image_format.aspect_ratio
          image.save!
        end
      end
    end

    namespace :tag do
      desc 'Set slug for existing tags when slug is empty'
      task :set_slug_when_empty => :environment do
        ActsAsTaggableOn::Tag.where("tags.slug IS NULL").find_each do |tag|
          tag.save
        end
      end
    end

    namespace :document do

      desc 'Clean rich_text segments'
      task :clean_rich_text_segments => :environment do
        count = Document.is_root.where("documents.rich_text IS NOT NULL").count
        puts "#{count} documents with rich_text found."
        Document.is_root.where("documents.rich_text IS NOT NULL").find_each do |document|
          Document::CleanRichTextJob.perform_later(document.id)
        end
      end

      desc 'Destroy only deleted documents and chunks permanently'
      task :create_rich_text_from_segments => :environment do
        count = Document.is_root.where("documents.rich_text IS NULL").count
        puts "#{count} documents with empty rich_text found."
        Document.is_root.where("documents.rich_text IS NULL").find_each do |document|
          Document::CreateRichTextJob.perform_later(document.id)
        end
      end

      desc 'Destroy only deleted documents and chunks permanently'
      task :really_destroy_only_deleted => :environment do
        Document.only_deleted.find_each do |document|
          document.really_destroy!
        end
      end

      desc 'Prune documents with removed uploads/ingests'
      task :prune => :environment do
        Document.is_root.find_each do |document|
          if document.ingests.empty?
            document.destroy
            puts "Document id=#{document.id} empty, thus, destroy."
          else
            if document.ingests.any? {|i| i.upload.nil? }
              document.destroy
              puts "Document id=#{document.id} ingest removed, thus, destroy."
            else
              puts "Document id=#{document.id} keep."
            end
          end
        end
      end

    end

    namespace :users do
      desc 'Upgrade when user_id was added to uploads'
      task :set_uploads_user_id => :environment do
        Upload.find_each do |upload|
          if upload.ingest.user.present?
            upload.update_attributes(user_id: upload.ingest.user.id)
          end
        end
      end
    end

    namespace :ingest do

      desc 'Prune ingests that are removed'
      task :prune => :environment do
        Ingest.removed.find_each do |ingest|
          ingest.destroy
          puts "Ingest id=#{ingest.id} removed, thus, destroy."
        end
      end

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
