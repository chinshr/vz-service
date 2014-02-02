class Qscribe.Models.Upload extends Backbone.Model
  urlRoot: 'api/uploads'
  
  validation:
    title:
      required: true
      
  parse: (response) ->
    response.upload
    
  toJSON: () ->
    {upload: _.clone(@.attributes)}

  hasFinished: () ->
    if @.attributes.status == 9
      true
    else
      false

  hasStopped: () ->
    if @.attributes.status == 4
      true
    else
      false
    
  hasProgress: () ->
    switch @.attributes.status
      when 0, 1, 2, 3, 5, 7 then true
      else 
        false

  message: () ->
    switch @.attributes.status
      when 0 then "Uploaded."
      when 1 then "Processing starting."
      when 2 then "Processing."
      when 3 then "Stopping."
      when 4 then "Stopped."
      when 5 then "Resetting."
      when 6 then "Reset."
      when 7 then "Removing."
      when 8 then "Removed."
      when 9 then "Finished."
      