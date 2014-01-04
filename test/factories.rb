FactoryGirl.define do

  factory :upload do
    sequence(:file_name) {|n| "sample-#{n}.m4a"}
    file_type "audio/x-m4a"
    file_size 62676
    sequence(:s3_url) {|n| "http://s3.amazonaws.com/dropbox/sample-#{n}.m4a"} 
  end

  factory :document do
    sequence(:title) {|n| "title-#{n}"}
    sequence(:description) {|n| "description-#{n}"}
  end

  factory :ingest_audio, :class => "Ingest::Audio" do
    association :upload
    association :ingestable, factory: :document
  end
  
end