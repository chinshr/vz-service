ActsAsTaggableOn::Tag.send(:include, Model::Filter)

ActsAsTaggableOn::Tag.class_eval do
  # public scopes
  filtered_scopes :most_used, :least_used
end
