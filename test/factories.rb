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
    association :user
    sequence(:title) {|n| "title-#{n}"}
    sequence(:description) {|n| "description-#{n}"}
  end

  factory :ingest_audio, :class => "Ingest::Audio" do
    association :upload, factory: :upload_audio
    association :ingestable, factory: :document
  end

  factory :document_chunk, :class => "Document::Chunk" do
    association :document
    offset 0
    duration 3.51
    start_time 0
    end_time 3.51
    text "I like pickles"
    processing_status 0
    score 0.59
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

  factory :user do
    sequence(:email) {|n| "test-#{n}@example.com"}
    sequence(:first_name) {|n| "first-name-#{n}"}
    sequence(:last_name) {|n| "last-name-#{n}"}
    confirmed_at Time.now.utc - 1.day
    current_sign_in_ip "95.63.14.59"
  end

  factory :backend_user, :class => "User", :parent => :user do
    roles_mask 2
  end

  factory :admin_user, :class => "User", :parent => :user do
    roles_mask 3
  end

  factory :track do
    sequence(:s3_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}"}
    sequence(:s3_mp3_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}-128kbps-mp3"}
  end

  factory :registration do
    # sequence(:email) {|n| "user#{n}@example.com" }
    email "test@example.com"
    locale 'en'
    country_code 'US'
    ip_address "127.0.0.1"
    time_zone "Paris"
    lat 48.864715
    lng 2.373047
    city "Paris"
    postal_code "1456"
    region_code "01"
    region_name "Paris City"
  end

  factory :social_registration do
    email "test@facebook.com"
    locale 'en'
    country_code 'US'
    ip_address "127.0.0.1"
    time_zone "Buenos Aires"
    lat -34.5875
    lng -58.6725
    city "Buenos Aires"
    postal_code "1640"
    region_code "07"
    region_name "Distrito Federal"
    first_name "Hans"
    last_name "Zimmer"
    opt_in false
    type "social_registration"
    uid "1234567890"
    referrer_uid "0123456789"
  end

end