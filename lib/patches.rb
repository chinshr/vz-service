ActsAsTaggableOn::Tag.send(:include, Model::Filter)

ActsAsTaggableOn::Tag.class_eval do
  filtered_scopes :most_used, :least_used, :named_like

  scope :named_like, -> (param) { where(self.arel_table[:name].matches("%#{param}%")) }
end
