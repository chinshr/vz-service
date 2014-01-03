window.Qscribe =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: -> 
    new Qscribe.Routers.Uploads()
    Backbone.history.start()

$(document).ready ->
  Qscribe.initialize()
  
