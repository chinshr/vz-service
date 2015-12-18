module Job::Helper

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    def s3_delete_object_if_exists(bucket_name, key)
      s3 = AWS::S3.new
      if bucket_name.present? && key.present? && s3.buckets[bucket_name].objects[key].exists?
        s3.buckets[bucket_name].objects.delete(key)
      end
      true
    rescue AWS::S3::Errors::NoSuchKey => ex
      false
    end

    # Delete "folders" from S3
    def s3_delete_objects_with_prefix(bucket_name, prefix)
      result = false
      s3 = AWS::S3.new

      bucket = s3.buckets[bucket_name]

      if bucket.exists? && prefix.present? && prefix.length > 5
        bucket.objects.with_prefix("#{prefix}/").delete_all
        bucket.objects.delete(prefix)
        result = true
      end
      result
    rescue AWS::S3::Errors::NoSuchKey => ex
      result
    end

  end

end