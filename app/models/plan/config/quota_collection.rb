class Plan::Config::QuotaCollection < Array
  include Model::Virtus::Collection

  collection_of Plan::Config::Quota
end
