class Qscribe.Models.Upload extends Backbone.Model
  urlRoot: 'api/uploads'
  
  parse: (response) ->
    response.upload
    
  toJSON: () ->
    {upload: _.clone(@.attributes)}

  message: () ->
    msg = switch @.attributes.status
      when 0 then "Finalized."
      when 1 then "Starting."
      when 2 then "Started."
      when 3 then "Stopping."
      when 4 then "Stopped."
      when 5 then "Resetting."
      when 6 then "Reset."
      when 7 then "Removing."
      when 8 then "Removed."
      when 9 then "Finished."
      