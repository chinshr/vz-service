FactoryGirl.define do

  factory :upload_audio, :class => "Upload::Audio" do
    sequence(:file_name) {|n| "sample-#{n}.m4a"}
    file_type "audio/x-m4a"
    file_size 62676
    sequence(:s3_url) {|n| "http://s3.amazonaws.com/dropbox/sample-#{n}.m4a"} 
    before(:create) do |upload|
      upload.build_ingest(type: "Ingest::Audio", upload: upload, ingestable: FactoryGirl.create(:document))
    end
  end

  factory :document do
    sequence(:title) {|n| "title-#{n}"}
    sequence(:description) {|n| "description-#{n}"}
  end

  factory :ingest_audio, :class => "Ingest::Audio" do
    association :upload, factory: :upload_audio
    association :ingestable, factory: :document
  end
  
end