class UploadListener

  def refresh_upload(upload)
    PubSub.publish upload.user, {
      command: :refresh_upload,
      data: {
        upload_id: upload.id,
        upload_uid: upload.uid,
        upload_type: upload.type,
        progress: upload.progress,
        state: upload.state,
        sequence: Time.zone.now.to_i
      }
    }
  rescue FailureResponseError => ex
    Rails.logger.info "PubNub exception: #{ex.message}"
  end

end