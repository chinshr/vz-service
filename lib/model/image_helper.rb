module Model::ImageHelper

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods

    def valid_image_content_type?(content_type)
      !!(content_type && content_type.match(/^(image)\/?.*$/i))
    end

  end

  module InstanceMethods

    def valid_image_file_type?
      self.class.valid_image_content_type?(file_type)
    end
    alias_method :valid_image_content_type?, :valid_image_file_type?

    private

    def target
      @target ||= Model::URI::Target.new(source_url)
    end

    def valid_image_source_url
      errors.add(:source_url, :invalid) unless target.valid?

      if has_s3_source_url?
        errors.add(:file_name, :presence) unless file_name.present?
        errors.add(:file_type, :media_expected) unless valid_image_file_type?
      else
        errors.add(:source_url, :unresolved, error: target.error) if target.valid? && !target.resolves?
        if target.valid? && target.resolves? && !target.valid_image_content_type?
          errors.add(:source_url, :unknown_content_type_or_video_service)
        end
      end
    end

  end # InstanceMethods
end # Model::ImageHelper
