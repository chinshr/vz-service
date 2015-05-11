FactoryGirl.define do

  factory :upload_audio, :class => "Upload::Audio" do
    sequence(:file_name) {|n| "sample-#{n}.m4a"}
    file_type "audio/x-m4a"
    file_size 62676
    recorded_at Time.parse("26/2/1972 15:32 UTC")
    sequence(:s3_url) {|n| "http://s3.amazonaws.com/dropbox/sample-#{n}.m4a"}
    before(:create) do |upload|
      upload.build_ingest(type: "Ingest::Audio", upload: upload, document: FactoryGirl.create(:document))
    end
  end

  factory :document do
    association :user
    sequence(:title) {|n| "title-#{n}"}
    sequence(:description) {|n| "description-#{n}"}
  end

  factory :document_with_track, parent: :document do
    association :track, factory: :master_track
  end

  factory :document_with_ingest, parent: :document do
    association :track, factory: :master_track
    before(:create) do |document|
      FactoryGirl.create(:ingest_audio, document: document)
    end
  end

  factory :ingest_audio, :class => "Ingest::Audio" do
    association :upload, factory: :upload_audio
    association :document, factory: :document_with_track
  end

  factory :ingest_audio_without_track, :class => "Ingest::Audio" do
    association :upload, factory: :upload_audio
    association :document, factory: :document
  end

  factory :chunk do
    association :document, factory: :document_with_track
    offset 0.0
    duration 3.51
    text "I like pickles"
    processing_status 0
    score 0.59
    before(:create) do |chunk|
      chunk.response = {"status" => 0, "id" => "ce178ea89f8b17d8e8298c9c7814700a-1", "hypotheses" => [["I like pickles", 0.59408695], ["I like turtles", 0.34534354], ["I like tickles", nil], ["I like to Kohl's", nil]]}
      chunk.position ||= chunk.document.chunks.count + 1
    end
  end

  factory :chunk_with_ingest, parent: :chunk do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest = chunk.document.ingests.first
    end
  end

  factory :chunk_google_speech, parent: :chunk, class: "Chunk::GoogleSpeech" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
    end
  end

  factory :chunk_att_speech, parent: :chunk, class: "Chunk::AttSpeech" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
    end
  end

  factory :chunk_nuance_dragon, parent: :chunk, class: "Chunk::NuanceDragon" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
    end
  end

  factory :chunk_pocketsphinx, parent: :chunk, class: "Chunk::Pocketsphinx" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
      chunk.build_track(FactoryGirl.attributes_for(:track).merge(ingest: chunk.document.ingests.first))
    end
  end

  factory :chunk_mechanical_turk, parent: :chunk, class: "Chunk::MechanicalTurk" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
      chunk.build_track(FactoryGirl.attributes_for(:track).merge(ingest: chunk.document.ingests.first))
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
    password "password"
    password_confirmation "password"
    sequence(:first_name) {|n| "first-name-#{n}"}
    sequence(:last_name) {|n| "last-name-#{n}"}
    confirmed_at Time.now.utc - 1.day
    current_sign_in_ip "95.63.14.59"
  end

  factory :unconfirmed_user, :class => "User", :parent => :user do
    confirmed_at nil
  end

  factory :backend_user, :class => "User", :parent => :user do
    roles_mask 2
  end

  factory :admin_user, :class => "User", :parent => :user do
    roles_mask 3
  end

  factory :developer_user, :class => "User", :parent => :user do
    roles_mask 4
  end

  factory :track do
    sequence(:s3_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}"}
    sequence(:s3_mp3_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}-128kbps-mp3"}
    sequence(:s3_waveform_json_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}-waveform.json"}
  end

  factory :master_track, parent: :track do
    is_master true
  end

  factory :track_with_chunk_and_ingest, parent: :track do
    association :document, factory: :chunk_google_speech
    before(:create) do |track|
      track.ingest = track.document.ingest
    end
  end

  factory :track_with_document_and_ingest, parent: :master_track do
    before(:create) do |track|
      ingest = FactoryGirl.create(:ingest_audio_without_track)
      track.document = ingest.document
      track.ingest = ingest
    end
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

  factory :client, class: "Api::Client" do
    sequence(:name) { |n| "iPhone-#{n}" }
    key { SecureRandom.hex(32) }
    association :platform
  end

  factory :platform, class: "Api::Platform" do
    sequence(:name)   { |n| "platform-#{n}" }
    version           "1.0"
    uid               { Api::Platform.generate_uid.slice(0..7) }
    aasm_state        "active"
  end

  factory :platform_with_clients, :parent => :platform do
    after(:create) do |platform|
      FactoryGirl.create(:client, :platform => platform)
    end
  end

  factory :client_access, class: "Api::ClientAccess" do
    access_secret "MyString"
    access_status { Api::ClientAccess::ACCESS_STATUS_CLIENT }
    aasm_state "active"
  end

  factory :device, class: "Api::Device" do
    uid 'ABVDEFGH'
    device_name 'Device Name'
  end

  factory :device_with_clients, :parent => :device do
    uid    '1234567890'
    after(:create) do |device|
      device.client = FactoryGirl.create(:client)
    end
  end

  factory :tracking do
    association :document
    association :track
  end

  factory :turkee_task, :class => Turkee::TurkeeTask do |s|
    s.hit_url "http://workersandbox.mturk.com/mturk/preview?groupId=248SVGULF395SZ65OC6S6NYNJDXAO5"
    s.sandbox true
    s.task_type "TestTask"
    s.hit_title "Test Title"
    s.hit_description "Test Desc"
    s.hit_id "123"
    s.hit_reward 0.05
    s.completed_assignments 0
    s.hit_num_assignments 100
    s.hit_lifetime 1
    s.hit_duration 1
    s.form_url "http://localhost/test_task/new"
    s.complete false
    s.expired false
    s.created_at Time.now
    s.updated_at Time.now
  end

end