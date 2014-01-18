class Qscribe.Models.Upload extends Backbone.Model
  urlRoot: 'api/uploads'
  # paramRoot: 'upload'
  
  parse: (response) ->
    response.upload
    
  toJSON: () ->
    {upload: _.clone(@.attributes)}
