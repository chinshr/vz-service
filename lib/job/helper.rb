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
  end

end