module Job::Helper

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    def s3_delete_object_if_exists(bucket_name, key)
      result = false
      s3 = AWS::S3.new
      if bucket_name.present? && key.present? && s3.buckets[bucket_name].objects[key].exists?
        s3.buckets[bucket_name].objects.delete(key)
        result = true
      end
      result
    rescue AWS::S3::Errors::NoSuchKey => ex
      false
    end

    def s3_object_exists?(bucket_name, key)
      s3 = AWS::S3.new
      bucket_name.present? && key.present? && s3.buckets[bucket_name].objects[key].exists?
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

    def s3_download_object(source_bucket_name, source_key, destination_filename)
      Rails.logger.info "-->> S3 download : #{source_bucket_name}, #{source_key}, #{destination_filename}"
      # create directory if not exists
      FileUtils::mkdir_p "/#{File.join(destination_filename.split("/").slice(1...-1))}"
      # download to folder
      s3 = AWS::S3.new
      File.open(destination_filename, 'wb') do |file|
        s3.buckets[source_bucket_name].objects[source_key].read do |chunk|
          file.write(chunk)
        end
      end
    end

    def s3_download_object_if_exists(source_bucket_name, source_key, destination_filename)
      result = false
      if s3_object_exists?(source_bucket_name, source_key)
        s3_download_object(source_bucket_name, source_key, destination_filename)
        result = true
      end
      result
    end

    def s3_copy_object_if_exists(source_bucket_name, source_key, destination_bucket_name, destination_key = nil)
      s3 = AWS::S3.new
      result = false
      destination_key = source_key if destination_key.nil?
      if s3.buckets[source_bucket_name].objects[source_key].exists?
        s3.buckets[source_bucket_name].objects[source_key].copy_to(destination_key, :bucket_name => destination_bucket_name)
        result = true
      end
      result
    end

    def s3_upload_object(local_file, bucket_name, key = nil)
      s3 = AWS::S3.new
      AWS.config.http_handler.pool.empty!

      key = File.basename(local_file) unless key
      Rails.logger.info "-->> start s3 upload: #{local_file}, #{bucket_name}, #{key}"
      if false
        s3.buckets[bucket_name].objects[key].write(:file => local_file)
      else
        s3.buckets[bucket_name].objects[key].write(File.open(local_file), content_length: File.size(local_file))
      end
      Rails.logger.info "-->> finished s3 upload: #{local_file}, #{bucket_name}, #{key}"
    end

    def delete_file_if_exists(file)
      Rails.logger.info "--> delete file #{file || '(empty)'} if exists"
      File.delete(file) if file && File.exist?(file)
    end

    def file_type(file_path)
      mt = if Rails.env.production?
        # Heroku
        `file -ib #{file_path}`.gsub(/\n/, "")
      else
        # BSD
        `file -Ib #{file_path}`.gsub(/\n/, "")
      end
      mt.split(";").first
    rescue
      nil
    end

  end
end
