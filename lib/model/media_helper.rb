module Model::MediaHelper

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

    protected

    def has_source_url?
      source_url.present?
    end

    # E.g. true for "http://s3.amazonaws.com/vz-dropbox/3o6njggbog03s5odak5y"
    def has_s3_source_url?
      result = false
      if source_url.present?
        uri = URI.parse(URI.encode(source_url))
        result = !!(uri.host.try(:match, /^s3.amazonaws.com$/i) &&
          uri.path.try(:match, /#{APP_CONFIG['S3_INBOUND_BUCKET']}/i))
      end
      result
    end

  end

end