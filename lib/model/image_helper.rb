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

  end # InstanceMethods
end # Model::ImageHelper