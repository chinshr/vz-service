require 'mini_magick'

# CDN: http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-task-list.html
# ImageMagick: http://www.imagemagick.org/Usage/resize/#shrink

class Ingest::ImageIngest::ProcessJob < ApplicationJob
  include Job::Helper

  queue_as :default

  attr_accessor :ingest

  def perform(ingest_id)
    if @ingest = Ingest.find(ingest_id)
      lock_ingest do
        harvest
        process
      end
    end
  rescue Exception => ex
    log_error(ex)
    raise ex
  ensure
    cleanup
  end

  protected

  def speedup?
    true
  end

  def harvest
    if ingest.has_s3_source_url?
      if speedup?
        s3_download_from_upload_or_origin_bucket
      else
        # copy object
        s3_copy_object_if_exists(
          ingest.s3_upload_bucket_name, ingest.handle,
          ingest.s3_origin_bucket_name, ingest.s3_origin_key)
        ingest.update_attributes(origin_url: ingest.s3_origin_url)

        # remove uploaded object
        s3_delete_object_if_exists(
          ingest.s3_upload_bucket_name, ingest.handle)

        # download object
        s3_download_object(
          ingest.s3_origin_bucket_name,
          ingest.s3_origin_key, original_file_fullpath)
      end
    else
      download_image_from_raw_source_url
      upload_raw_file_to_s3_outbound_bucket
    end
    increment_progress! 20
  end

  def process
    image = MiniMagick::Image.open(original_file_fullpath)
    image_aspect_ratio = image.width / image.height.to_f

    ingest.update_attributes(metadata: {target: image.details})

    Image::ImageFormat.find_each do |format|
      # if (image.width == format.width && image.height == format.height) || (format.is_source && image_aspect_ratio >= (format.aspect_ratio - 0.01) && image_aspect_ratio <= (format.aspect_ratio + 0.01))
      if format.is_source && ((image_aspect_ratio >= 1 && format.aspect_ratio >=1) || image_aspect_ratio <= 1 && format.aspect_ratio <=1)
        file_path = resize(image, format, {gravity: 'center', extent: true})
        file_name = file_path.split('/').last
        s3_key    = "#{ingest.uid}/#{file_name}"

        # copy to S3
        s3_upload_object(file_path,
          ingest.s3_origin_bucket_name, s3_key)

        # create image
        Image.create({
          ingest: ingest,
          path: s3_key,
          size: File.size(file_path),
          image_format: format
        })

        # remove from file system
        delete_file_if_exists(file_path)
      end
      increment_progress! 20
    end
  end

  def cleanup
    if ingest.has_s3_source_url? && speedup?
      # copy object
      s3_copy_object_if_exists(
        ingest.s3_upload_bucket_name, ingest.handle,
        ingest.s3_origin_bucket_name, ingest.s3_origin_key)
      ingest.update_attributes(origin_url: ingest.s3_origin_url)

      # remove uploaded object
      s3_delete_object_if_exists(
        ingest.s3_upload_bucket_name, ingest.handle)
    end

    delete_file_if_exists(original_file_fullpath)
  end

  private

  def download_image_from_raw_source_url
    # create directory if not exists
    FileUtils::mkdir_p "/#{File.join(original_file_fullpath.split("/").slice(1...-1))}"

    File.open(original_file_fullpath, "wb") do |saved_file|
      open(ingest.source_url, "rb") do |read_file|
        saved_file.write(read_file.read)
      end
    end

    # determine file_type/size and update ingest
    ingest.update_attributes({
      file_type: file_type(original_file_fullpath),
      file_size: File.size(original_file_fullpath)
    })
    original_file_fullpath
  end

  def upload_raw_file_to_s3_outbound_bucket
    s3_upload_object(original_file_fullpath,
      ingest.s3_origin_bucket_name, ingest.s3_origin_key)
  end

  def basefolder
    File.join("/tmp", ingest.uid)
  end

  def original_file
    ingest.handle if ingest && ingest.handle
  end

  def original_file_fullpath
    File.join(basefolder, original_file) if original_file
  end

  def resize(image, image_format, options = {})
    options.reverse_merge!({gravity: 'center', extent: true})
    image  = MiniMagick::Image.open(original_file_fullpath)
    image.format image_format.format # 'jpeg'

    name   = "#{ingest.handle}-#{image_format.width}x#{image_format.height}.#{image_format.format}"
    output = File.join(basefolder, name)

    image.combine_options do |c|
      c.resize "#{image_format.width}x#{image_format.height}^"
      c.gravity options[:gravity] if options[:gravity]
      c.extent "#{image_format.width}x#{image_format.height}" if options[:extent]
    end
    image.write(output)
    output
  end

  def lock_ingest
    result = false
    ingest.with_lock do
      if !ingest.busy && !ingest.terminate && ingest.process!
        result = true
        ingest.update_attributes(progress: 1, busy: true)
      end
    end
    # execute block
    if result
      yield
      ingest.finish!
      unlock_ingest
    end
    result
  end

  def unlock_ingest
    ingest.with_lock do
      ingest.update_attributes(busy: false)
    end
  end

  def increment_progress!(increment = 1, max_progress = 100)
    progress = ingest.progress
    progress += increment
    ingest.update_attribute(:progress, progress) if progress < max_progress
    ingest
  end

  def s3_download_from_upload_or_origin_bucket
    unless s3_download_object_if_exists(
      ingest.s3_upload_bucket_name,
      ingest.handle, original_file_fullpath)

      unless s3_download_object_if_exists(
        ingest.s3_origin_bucket_name,
        ingest.s3_origin_key, original_file_fullpath)
        raise "Original file cannot be found on S3."
      end
    end
  end

  def log_error(error)
    if ingest
      stage_name   = 'process'
      new_messages = ingest.messages || {}
      new_messages[stage_name] ||= {}
      new_messages[stage_name]["message"] = error.message
      if error.backtrace
        new_messages[stage_name]["backtrace"] = error.backtrace
      end
      ingest.update_attributes({messages: new_messages})
    end
    Rails.logger.error error.message
    Rails.logger.error error.backtrace * "\n" if error.backtrace
    error
  end
end
