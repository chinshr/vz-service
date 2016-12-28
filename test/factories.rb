FactoryGirl.define do

  factory :media_upload_as_audio, :class => "Upload::MediaUpload" do
    sequence(:source_url) {|n| "http://s3.amazonaws.com/vz-test-dropbox/sample-#{n}.m4a"}
    sequence(:file_name) {|n| "sample-#{n}.m4a"}
    file_type "audio/x-m4a"
    file_size 62676
    recorded_at Time.parse("26/2/1972 15:32 UTC")
    before(:create) do |upload|
      upload.ingest.document = FactoryGirl.build(:document)
    end
  end

  factory :media_upload_as_video, :class => "Upload::MediaUpload" do
    sequence(:source_url) {|n| "http://s3.amazonaws.com/vz-test-dropbox/sample-video-#{n}.mp4"}
    sequence(:file_name) {|n| "sample-video-#{n}.mp4"}
    file_type "video/mp4"
    file_size 62676676
    recorded_at Time.parse("26/4/1974 15:32 UTC")
    before(:create) do |upload|
      upload.ingest.document = FactoryGirl.build(:document)
    end
  end

  factory :image_upload, :class => "Upload::ImageUpload" do
    sequence(:source_url) {|n| "http://s3.amazonaws.com/vz-test-dropbox/sample-#{n}.jpg"}
    sequence(:file_name) {|n| "sample-#{n}.jpg"}
    file_type "image/jpeg"
    file_size 45983

    trait :ingestable do
      before(:create) do |upload|
        upload.ingest.ingestable = FactoryGirl.build(:document)
      end
    end
  end

  factory :document do
    association :user
    sequence(:title) {|n| "title-#{n}"}
    sequence(:description) {|n| "description-#{n}"}

    trait :keywords do
      response({
        "status" => 3,
        "id" => "ce178ea89f8b17d8e8298c9c7814700a-1",
        "keywords" => [
          {"id" => "89f8b1", "text" => "pickle", "relevance" => "0.974", "emotions" => {"joy" => "0.0231", "fear" => "0.0123", "anger" => "0.2344", "disgust" => "0.234", "sadness" => "0.23432"}, "sentiment" => {"type" => "neutral", "score" => "0.08423"}},
        ]
      })
    end

    trait :entities do
      response({
        "status" => 3,
        "id" => "ce178ea89f8b17d8e8298c9c7814700a-1",
        "entities" => [{"id" => "abcd1", "type"=>"Person", "relevance"=>"0.948322", "count"=>"1", "text"=>"Donald Trump", "disambiguated"=>{"sub_type"=>["AwardNominee", "AwardWinner", "Celebrity", "CompanyFounder", "TVPersonality", "TVProducer", "FilmActor", "TVActor"], "name"=>"Donald Trump", "website"=>"http://www.trumponline.com/", "dbpedia"=>"http://dbpedia.org/resource/Donald_Trump", "freebase"=>"http://rdf.freebase.com/ns/m.0cqt90", "opencyc"=>"http://sw.opencyc.org/concept/Mx4rv0ncIZwpEbGdrcN5Y29ycA", "yago"=>"http://yago-knowledge.org/resource/Donald_Trump"}}, {"id" => "abcd2", "type"=>"FieldTerminology", "relevance"=>"0.89276", "count"=>"1", "text"=>"diplomatic relations"}, {"id" => "abcd3", "type"=>"Country", "relevance"=>"0.802341", "count"=>"2", "text"=>"United States", "disambiguated"=>{"sub_type"=>["Location", "Region", "AdministrativeDivision", "GovernmentalJurisdiction", "FilmEditor"], "name"=>"United States", "website"=>"http://www.usa.gov/", "dbpedia"=>"http://dbpedia.org/resource/United_States", "freebase"=>"http://rdf.freebase.com/ns/m.09c7w0", "ciaFactbook"=>"http://www4.wiwiss.fu-berlin.de/factbook/resource/United_States", "opencyc"=>"http://sw.opencyc.org/concept/Mx4rvVikKpwpEbGdrcN5Y29ycA", "yago"=>"http://yago-knowledge.org/resource/United_States"}}, {"id" => "abcd4", "type"=>"JobTitle", "relevance"=>"0.727315", "count"=>"1", "text"=>"president-elect"}, {"id" => "abcd5", "type"=>"Country", "relevance"=>"0.6751", "count"=>"2", "text"=>"Taiwan", "disambiguated"=>{"sub_type"=>["Location", "GeographicFeature", "Island"], "name"=>"Taiwan", "geo"=>"23.766666666666666 121.0", "dbpedia"=>"http://dbpedia.org/resource/Taiwan", "freebase"=>"http://rdf.freebase.com/ns/m.06f32", "ciaFactbook"=>"http://www4.wiwiss.fu-berlin.de/factbook/resource/Taiwan", "yago"=>"http://yago-knowledge.org/resource/Taiwan"}}, {"id" => "abcd6", "type"=>"JobTitle", "relevance"=>"0.53834", "count"=>"1", "text"=>"president"}, {"id" => "abcd7", "type"=>"JobTitle", "relevance"=>"0.382965", "count"=>"1", "text"=>"official"}]
      })
    end
  end

  factory :document_with_track, parent: :document do
    association :track, factory: :master_track
  end

  factory :document_with_ingest, parent: :document do
    association :track, factory: :master_track
    before(:create) do |document|
      FactoryGirl.create(:media_ingest_as_audio, document: document)
    end
  end

  factory :media_ingest_as_audio, :class => "Ingest::MediaIngest" do
    sequence(:source_url) {|n| "http://s3.amazonaws.com/vz-test-dropbox/sample-#{n}.m4a"}
    sequence(:file_name) {|n| "sample-#{n}.m4a"}
    file_type "audio/x-m4a"
    file_size 62676
    association :document, factory: :document_with_track
    before(:create) do |ingest|
      ingest.upload = FactoryGirl.build(:media_upload_as_audio, ingest: ingest)
    end
    after(:create) do |ingest|
      ingest.document.master_segment.ingest_id = ingest.id
      ingest.document.master_segment.save
    end
  end

  factory :media_ingest_as_audio_without_track, :class => "Ingest::MediaIngest" do
    association :upload, factory: :media_upload_as_audio
    association :document, factory: :document
  end

  factory :media_ingest_as_video, :class => "Ingest::MediaIngest" do |i|
    sequence(:source_url) {|n| "http://s3.amazonaws.com/vz-test-dropbox/sample-video-#{n}.mp4"}
    sequence(:file_name) {|n| "sample-video-#{n}.mp4"}
    file_type "video/mp4"
    file_size 62676676
    association :document, factory: :document_with_track
    before(:create) do |ingest|
      ingest.upload = FactoryGirl.build(:media_upload_as_video, ingest: ingest)
    end
    after(:create) do |ingest|
      ingest.document.master_segment.ingest_id = ingest.id
      ingest.document.master_segment.save
    end
  end

  factory :media_ingest_as_video_without_track, :class => "Ingest::MediaIngest" do
    association :upload, factory: :media_upload_as_video
    association :document, factory: :document
  end

  factory :image_ingest, :class => "Ingest::ImageIngest" do |i|
    sequence(:source_url) {|n| "http://s3.amazonaws.com/vz-test-dropbox/sample-image-#{n}.jpg"}
    sequence(:file_name) {|n| "sample-image-#{n}.jpg"}
    file_type "image/jpeg"
    file_size 49142

    trait :ingestable_document do
      association :ingestable, factory: :document_with_track
    end

    trait :ingestable_document_with_ingest do
      association :ingestable, factory: :document_with_ingest
    end
  end

  factory :chunk do
    association :document, factory: :document_with_track
    offset 0.0
    text "I like pickles"
    processing_status 0
    score 0.59
    before(:create) do |chunk|
      chunk.response = {
        "status" => 0,
        "id" => "ce178ea89f8b17d8e8298c9c7814700a-1",
        "hypotheses" => [
          {"utterance" => "I like pickles", "confidence" => 0.59408695},
          {"utterance" => "I like turtles", "confidence" => 0.34534354},
          {"utterance" => "I like tickles", "confidence" => nil},
          {"utterance" => "I like to Kohl's", "confidence" => nil}
        ]
      }.merge(chunk.response.as_json.reject {|k,v| v.blank?})
    end

    trait :hypotheses do
      response({
        "status" => 3,
        "id" => "ce178ea89f8b17d8e8298c9c7814700a-1",
        "hypotheses" => [
          {"utterance" => "I like pickles", "confidence" => 0.59408695},
          {"utterance" => "I like turtles", "confidence" => 0.34534354},
          {"utterance" => "I like tickles", "confidence" => nil},
          {"utterance" => "I like to Kohl's", "confidence" => nil}
        ]
      })
    end

    trait :keywords do
      response({
        "status" => 3,
        "id" => "ce178ea89f8b17d8e8298c9c7814700a-1",
        "keywords" => [
          {"id" => "89f8b1", "text" => "pickle", "relevance" => "0.974", "emotions" => {"joy" => "0.0231", "fear" => "0.0123", "anger" => "0.2344", "disgust" => "0.234", "sadness" => "0.23432"}, "sentiment" => {"type" => "neutral", "score" => "0.08423"}},
        ]
      })
    end

    trait :words do
      response({
        "words" => [{"p":1,"c":0.7,"s":1610,"e":1780,"w":"This"},{"p":2,"c":0.714,"s":1780,"e":1960,"w":"is"},{"p":3,"c":0.502,"s":1960,"e":2440,"w":"Tom"},{"p":4,"c":0.506,"s":2440,"e":2960,"w":"Cook"},{"p":5,"c":0.501,"s":2960,"e":3200,"w":"car"},{"p":6,"c":0.51,"s":3200,"e":3340,"w":"team"},{"p":7,"c":0,"s":3340,"e":3560,"w":".","m":"punc"},{"p":8,"c":0.589,"s":3560,"e":3800,"w":"This"},{"p":9,"c":0.733,"s":3800,"e":3860,"w":"is"},{"p":10,"c":0.731,"s":3860,"e":4300,"w":"a"},{"p":11,"c":0.511,"s":4300,"e":4450,"w":"production"},{"p":12,"c":0,"s":4450,"e":5140,"w":".","m":"punc"},{"p":13,"c":0.501,"s":5140,"e":5510,"w":"Verification"},{"p":14,"c":0.53,"s":5510,"e":5590,"w":"video"},{"p":15,"c":0.783,"s":5590,"e":5959,"w":"of"},{"p":16,"c":0.749,"s":5960,"e":6310,"w":"a"},{"p":17,"c":0.813,"s":6310,"e":6580,"w":"new"},{"p":18,"c":0.54,"s":6580,"e":7370,"w":"feature"},{"p":19,"c":0,"s":7370,"e":8120,"w":".","m":"punc"},{"p":20,"c":0.774,"s":8120,"e":8480,"w":"The"},{"p":21,"c":0.529,"s":8480,"e":8709,"w":"future"},{"p":22,"c":0.789,"s":8710,"e":9290,"w":"is"},{"p":23,"c":0.501,"s":9290,"e":9730,"w":"direct"},{"p":24,"c":0.538,"s":9730,"e":10240,"w":"video"},{"p":25,"c":0.501,"s":10240,"e":10460,"w":"uploads"},{"p":26,"c":0.803,"s":10460,"e":10670,"w":"to"},{"p":27,"c":0.501,"s":10670,"e":10790,"w":"S"},{"p":28,"c":0.782,"s":10790,"e":11300,"w":"three"},{"p":29,"c":0.68,"s":11300,"e":11790,"w":"from"},{"p":30,"c":0.505,"s":11790,"e":12080,"w":"Android"},{"p":31,"c":0.685,"s":12080,"e":12910,"w":"devices"},{"p":32,"c":0,"s":12910,"e":13560,"w":".","m":"punc"},{"p":33,"c":0.517,"s":13590,"e":13760,"w":"If"},{"p":34,"c":0.735,"s":13760,"e":14110,"w":"this"},{"p":35,"c":0.709,"s":14110,"e":14470,"w":"video"},{"p":36,"c":0.517,"s":14470,"e":15079,"w":"upload"},{"p":37,"c":0.501,"s":15080,"e":15250,"w":"successful"},{"p":38,"c":0.523,"s":15250,"e":15340,"w":"even"},{"p":39,"c":0.579,"s":15340,"e":15650,"w":"I"},{"p":40,"c":0.844,"s":15650,"e":15800,"w":"believe"},{"p":41,"c":0.801,"s":15800,"e":16180,"w":"this"},{"p":42,"c":0.508,"s":16180,"e":16210,"w":"test"},{"p":43,"c":0.755,"s":16210,"e":16960,"w":"is"},{"p":44,"c":0.539,"s":16960,"e":17620,"w":"complete"},{"p":45,"c":1,"s":17620,"e":18170,"w":"and"},{"p":46,"c":0.769,"s":18170,"e":18440,"w":"the"},{"p":47,"c":0.504,"s":18440,"e":18530,"w":"feature"},{"p":48,"c":0.754,"s":18530,"e":18950,"w":"is"},{"p":49,"c":0.505,"s":18950,"e":19710,"w":"verified"},{"p":50,"c":0,"s":19710,"e":19710,"w":".","m":"punc"}]
      })
    end

    trait :speaker_segment do
      response({
        "speaker_segment"=>{"gender"=>"M", "duration"=>13.3100004196167, "end_time"=>13.420000419020653, "bandwidth"=>"U", "speaker_id"=>"S0", "start_time"=>0.10999999940395355, "speaker_model_uri"=>"http://www.example.com/o/896d36d4/S0.gmm", "speaker_supervector_hash"=>"-271324790387066728", "speaker_mean_log_likelihood"=>-31.339274605309463}
      })
    end

    trait :errors do
      response({
        "status" => -1,
        "external_status" => "(c21r)",
        "id" => "ab345ae89f8b17d8e8298c9c7814700a-9",
        "errors" => ["Split error"]
      })
    end
  end

  factory :chunk_with_ingest, parent: :chunk do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest = chunk.document.ingests.first
    end
  end

  factory :chunk_google_speech, parent: :chunk, class: "Chunk::GoogleSpeechChunk" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest = chunk.document.ingests.first
      # chunk.track_id  = FactoryGirl.create(:track).id
    end
  end

  factory :chunk_att_speech, parent: :chunk, class: "Chunk::AttSpeechChunk" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
    end
  end

  factory :chunk_nuance_dragon, parent: :chunk, class: "Chunk::NuanceDragonChunk" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
    end
  end

  factory :chunk_pocketsphinx, parent: :chunk, class: "Chunk::PocketsphinxChunk" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
      chunk.track_id  = FactoryGirl.create(:track).id
    end
  end

  factory :chunk_mechanical_turk, parent: :chunk, class: "Chunk::MechanicalTurkChunk" do
    association :document, factory: :document_with_ingest
    before(:create) do |chunk|
      chunk.ingest_id = chunk.document.ingests.first.id
      chunk.track_id  = FactoryGirl.create(:track).id
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
    sequence(:username) {|n| "user#{n}"}
    password "password"
    password_confirmation "password"
    sequence(:first_name) {|n| "first-name-#{n}"}
    sequence(:last_name) {|n| "last-name-#{n}"}
    confirmed_at Time.zone.now - 1.day
    current_sign_in_ip "95.63.14.59"

    trait :unconfirmed do
      confirmed_at nil
    end
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

  factory :track, class: "Track::ChunkTrack" do
    sequence(:s3_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}"}
    sequence(:s3_mp3_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}-128kbps-mp3"}
    sequence(:s3_waveform_json_url) {|n| "http://s3.amazonaws.com/private/zp66vfwg21-#{n}-waveform.json"}
    duration 3.51
    before(:create) do |track|
      track.start_at = Time.zone.now - 1.day
      track.end_at   = track.start_at + track.duration
    end
  end

  factory :master_track, parent: :track, class: "Track::DocumentTrack" do
  end

  factory :track_with_chunk_and_ingest, parent: :track do
    before(:create) do |track|
      chunk = FactoryGirl.create(:chunk_google_speech)
      chunk.track = track
    end
  end

  factory :track_with_document_and_ingest, parent: :master_track do
    before(:create) do |track|
      document = FactoryGirl.create(:document_with_ingest)
      track.document = document
      #track.segment.type = "Segment::DocumentSegment"
      track.ingest   = document.ingests.first
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

  factory :segment do
    association :document
    association :track
    association :chunk
    before(:create) do |segment|
      segment.position = segment.chunk.position
    end
  end

  factory :document_segment, parent: :segment, class: "Segment::DocumentSegment" do
  end

  factory :chunk_segment, parent: :segment, class: "Segment::ChunkSegment" do
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
    s.created_at Time.zone.now
    s.updated_at Time.zone.now
  end

  factory :cpw_ingest_server, :class => Ingest::Server::CPWServer do
    name "cpw"
    version "1.0.0"
    public_ip_address "57.12.54.12"
    private_ip_address "10.1.1.123"
    vpc_id nil
    number 1
    max_workers 5
    region "us-east-1"
    dns "vz-cpw-1.sample-voyzes.com"
    sequence(:instance_id) {|n| "xyz-#{n}"}
    tenancy :shared
    aasm_state "pending"

    trait :enabled do
      aasm_state "enabled"
    end

    trait :disabled do
      aasm_state "disabled"
    end
  end

  factory :cpw_ingest_process, :class => "Ingest::Process" do
    association :ingest, factory: :media_ingest_as_audio
    association :server, factory: :cpw_ingest_server
  end

  factory :image, :class => Image do
    sequence(:path) { |n| "path-#{n}" }
    sequence(:size) { |n| (1000 + n) }
    # width 500
    # height 500
    # format 'jpg'
    # aspect_ratio 1.0
    association :image_format

    trait :document_ingest do
      association :ingest, factory: [:image_ingest, :ingestable_document]
    end
  end

  factory :image_format, :class => Image::ImageFormat do
    format "jpg"
    width 1024
    height 768
    aspect_ratio (1024 / 768.to_f)
  end

  factory :ingest_worker, :class => "Ingest::Worker" do
    association :ingest, factory: :media_ingest_as_audio
    ingest_iteration 1
    worker_name "ingest/media_ingest/harvest_worker"
    worker_object_id "70365892547420"

    trait :created do
      aasm_state "created"
    end

    trait :running do
      aasm_state "running"
    end

    trait :stopped do
      aasm_state "stopped"
    end

    trait :finished do
      aasm_state "finished"
    end

    trait :failed do
      aasm_state "failed"
    end
  end

end
