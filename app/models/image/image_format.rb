class Image::ImageFormat < ActiveRecord::Base
  include Model::Filter
  include Model::Uid

  self.table_name = "image_formats"

  filtered_scopes :platform_id,
    :width_eq, :width_lt, :width_lteq, :width_gt, :width_gteq,
    :height_eq, :height_gt, :height_gteq, :height_lt, :height_lteq,
    :aspect_ratio_eq, :aspect_ratio_gt, :aspect_ratio_gteq, :aspect_ratio_lt, :aspect_ratio_lteq
  scope :platform_id, -> (param) { joins(:platforms).where(:platforms => {:id => param}) }
  scope :width_eq, -> (param) { where(self.arel_table[:width].eq(param)) }
  scope :width_lt, -> (param) { where(self.arel_table[:width].lt(param)) }
  scope :width_lteq, -> (param) { where(self.arel_table[:width].lteq(param)) }
  scope :width_gt, -> (param) { where(self.arel_table[:width].gt(param)) }
  scope :width_gteq, -> (param) { where(self.arel_table[:width].gteq(param)) }
  scope :height_eq, -> (param) { where(self.arel_table[:height].eq(param)) }
  scope :height_lt, -> (param) { where(self.arel_table[:height].lt(param)) }
  scope :height_lteq, -> (param) { where(self.arel_table[:height].lteq(param)) }
  scope :height_gt, -> (param) { where(self.arel_table[:height].gt(param)) }
  scope :height_gteq, -> (param) { where(self.arel_table[:height].gteq(param)) }
  scope :aspect_ratio_eq, -> (param) { where(self.arel_table[:aspect_ratio].eq(param)) }
  scope :aspect_ratio_lt, -> (param) { where(self.arel_table[:aspect_ratio].lt(param)) }
  scope :aspect_ratio_lteq, -> (param) { where(self.arel_table[:aspect_ratio].lteq(param)) }
  scope :aspect_ratio_gt, -> (param) { where(self.arel_table[:aspect_ratio].gt(param)) }
  scope :aspect_ratio_gteq, -> (param) { where(self.arel_table[:aspect_ratio].gteq(param)) }

  before_validation :set_aspect_ratio

  class << self

    def generate_uid
      SecureRandom.uuid
    end

  end

  def set_aspect_ratio
    self.aspect_ratio = ((self.width / self.height.to_f) * 100).round / 100.0
  end

end
