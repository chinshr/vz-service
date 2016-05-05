class UploadListener

  def refresh_upload(upload)
    PubSub.publish(upload.user, {
      "refresh-upload" => upload_hash(upload),
      "sequence"       => Time.zone.now.to_i
    })
  rescue FailureResponseError => ex
    Rails.logger.error "PubNub exception: #{ex.message}"
  end

  private

  def upload_hash(upload)
    hash = Rabl::Renderer.new(template(upload), upload, :view_path => 'app/views', :format => 'hash').render
    hash[:upload_id]   = hash.delete(:id)
    hash[:upload_uid]  = hash.delete(:uid)
    hash[:upload_type] = hash.delete(:type)
    hash
  end

  def template(upload)
    if upload.is_a?(Upload::MediaUpload)
      'api/account/uploads/show'
    else
      'api/uploads/show'
    end
  end
end