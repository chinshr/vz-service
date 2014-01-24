class Qscribe.Models.Upload extends Backbone.Model
  urlRoot: 'api/uploads'
  
  validation:
    title:
      required: true
      
  parse: (response) ->
    response.upload
    
  toJSON: () ->
    {upload: _.clone(@.attributes)}

  message: () ->
    msg = switch @.attributes.status
      when 0 then "Uploaded."
      when 1 then "Transcoding started."
      when 2 then "Transcoding."
      when 3 then "Transcoding stopping."
      when 4 then "Stopped."
      when 5 then "Resetting."
      when 6 then "Reset."
      when 7 then "Removing."
      when 8 then "Removed."
      when 9 then "Finished."
      