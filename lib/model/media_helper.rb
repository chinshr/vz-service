module Model::MediaHelper

  TARGET_MAX_NUMBER_OF_KEYWORDS = 100

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods

    def valid_media_content_type?(content_type)
      valid_video_content_type?(content_type) || valid_audio_content_type?(content_type)
    end

    def valid_video_content_type?(content_type)
      !!(content_type && content_type.match(/^(video)\/?.*$/i))
    end

    def valid_audio_content_type?(content_type)
      !!(content_type && content_type.match(/^(audio)\/?.*$/))
    end

    def humanize_path(path)
      return if path.blank?
      result = URI.decode(path)
      result = result.mb_chars
      result = result.split(/[\\\/]/).last
      result = result.split(".").first unless result.blank?
      result.gsub!(/[-+]+/, ' ') unless result.blank?
      result = result.strip.humanize.titleize unless result.blank?
      result.to_s
    end

    def humanize_url(url)
      uri = URI.parse(URI.encode(url))
      humanize_path(uri.path) unless uri.path.blank?
    rescue URI::InvalidURIError
      nil
    end
  end

  module InstanceMethods

    def valid_media_file_type?
      self.class.valid_media_content_type?(file_type)
    end
    alias_method :valid_media_content_type?, :valid_media_file_type?

    def valid_audio_file_type?
      self.class.valid_audio_content_type?(file_type)
    end
    alias_method :valid_audio_content_type?, :valid_audio_file_type?

    def valid_video_file_type?
      self.class.valid_video_content_type?(file_type)
    end
    alias_method :valid_video_content_type?, :valid_video_file_type?

    def humanize_path(path)
      self.class.humanize_path(path)
    end

    def humanize_url(url)
      self.class.humanize_url(url)
    end

    private

    def has_source_url?
      source_url.present?
    end

    def has_origin_url?
      origin_url.present?
    end

    def target
      @target ||= Model::URI::Target.new(source_url)
    end

    def set_media_attributes
      set_media_attributes_from_target
      set_media_attributes_from_metadata
    end

    def set_media_attributes_from_target
      if has_source_url? && !has_s3_source_url? && target.valid? && target.resolves?
        self.source_url = target.url
        self.file_type  = target.content_type if self.class.valid_media_content_type?(target.content_type)
        # set metadata
        hash = {}
        hash['target']  = target.metadata unless target.metadata.blank?
        self.metadata   = hash
      end
    end

    def set_media_attributes_from_metadata
      # title
      if title.blank?
        if metadata['target'] && metadata['target']['title']
          self.title = humanize_path(metadata['target']['title'])
        elsif file_name.present?
          self.title = humanize_path(file_name)
        elsif source_url.present?
          self.title = humanize_url(source_url)
        end
      end
      # description
      if description.blank?
        if metadata['target'] && metadata['target']['description'].present?
          self.description = metadata['target']['description']
        end
      end
      # tags
      if tag_list.blank?
        if metadata['target'] && metadata['target']['keywords'].present?
          self.tag_list = metadata['target']['keywords'].slice(0, TARGET_MAX_NUMBER_OF_KEYWORDS)
        end
      end
    end

    def valid_media_source_url
      errors.add(:source_url, :invalid) unless target.valid?
      if has_s3_source_url?
        errors.add(:file_name, :presence) unless file_name.present?
        errors.add(:file_type, :media_expected) unless valid_media_file_type?
      else
        errors.add(:source_url, :unresolved, error: target.error) if target.valid? && !target.resolves?
        if target.valid? && target.resolves? && !(target.valid_media_service? || target.valid_media_content_type?)
          errors.add(:source_url, :unknown_content_type_or_video_service)
        end
      end
    end

  end
end
