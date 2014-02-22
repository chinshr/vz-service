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

  factory :ingest_audio_segment, :class => "Ingest::Audio::Segment" do
    association :ingest, factory: :ingest_audio
    offset 0
    duration 3.51
    start_time 0
    end_time 3.51
    best_text "I like pickles"
    best_score 0.59
    before(:create) do |segment|
      segment.response = {"status" => 0, "id" => "ce178ea89f8b17d8e8298c9c7814700a-1", "hypotheses" => [["I like pickles", 0.59408695], ["I like turtles", 0.34534354], ["I like tickles", nil], ["I like to Kohl's", nil]]}
    end
  end
  
  factory :message do
    from "sender@example.com"
    to "receiver@example.com"
  end

  factory :inbound_message, :class => "Message::Inbound", :parent => :message do
    to "inbound@example.com"
  end
  
end