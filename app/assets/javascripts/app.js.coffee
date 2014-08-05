window.App =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: -> 
    new App.Routers.Uploads()
    Backbone.history.start()

$(document).ready ->
  App.initialize()
  
