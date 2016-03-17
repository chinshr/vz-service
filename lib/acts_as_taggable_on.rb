ActsAsTaggableOn::Tag.send(:include, Model::Filter)

ActsAsTaggableOn::Tag.class_eval do
  extend FriendlyId

  friendly_id :name, use: [:slugged]

  filtered_scopes :most_used, :least_used, :named_like
  scope :named_like, -> (param) {
    names = self.arel_table[:name].matches("%#{param}%")
    slugs = self.arel_table[:slug].matches("%#{param}%")
    where(names.or(slugs))
  }
  scope :slugged_like, -> (param) {
    slugs = self.arel_table[:slug].matches("%#{param}%")
    where(slugs)
  }

  # def to_param
  #   name.to_s.parameterize
  # end

  private

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || !!changes[:name]
  end

end
