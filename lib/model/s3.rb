module Model::S3

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
  end

  module InstanceMethods
    def s3_base_url
      APP_CONFIG['S3_URL']
    end

    def s3_upload_bucket_name
      APP_CONFIG['S3_INBOUND_BUCKET']
    end

    def s3_origin_bucket_name
      APP_CONFIG['S3_OUTBOUND_BUCKET']
    end

    def ingest_uid
      if self.is_a?(Ingest)
        uid
      elsif self.is_a?(Upload)
        ingest.uid
      else
        raise RuntimeError, "Missing #ingest_uid"
      end
    end

    def s3_origin_key
      if has_origin_url?
        path = URI.parse(origin_url).path.split("/").reject(&:blank?)
        File.join(path.slice(1..-1)) if path && path.length > 0
      else
        File.join(ingest_uid, File.basename(handle))
      end
    rescue URI::InvalidURIError => ex
      nil
    end

    def s3_origin_url
      if has_origin_url?
        self[:origin_url]
      else
        File.join(s3_base_url, s3_origin_bucket_name, s3_origin_key)
      end
    end

    # E.g. true for "http://s3.amazonaws.com/vz-dropbox/3o6njggbog03s5odak5y"
    def has_s3_source_url?
      result = false
      if has_source_url?
        uri = URI.parse(URI.encode(source_url))
        result = !!(uri.host.try(:match, /^s3.amazonaws.com$/i) &&
          uri.path.try(:match, /#{APP_CONFIG['S3_INBOUND_BUCKET']}/i))
      end
      result
    end

    private

    def has_source_url?
      source_url.present?
    end

    def has_origin_url?
      origin_url.present?
    end
  end
end
