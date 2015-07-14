namespace :document do
  namespace :slugs do
    desc "Update documents when slug is empty"
    task :set_default => :environment do
      ::Document.where("documents.slug IS NULL").find_each do |document|
        document.slug_id = document.slug_id.downcase if document.slug_id
        document.send(:title_and_slug_id)
        document.save!
      end
    end
  end
end