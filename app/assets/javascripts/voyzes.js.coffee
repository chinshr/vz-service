window.Voyzes =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: -> 
    new Voyzes.Routers.Uploads()
    Backbone.history.start()

$(document).ready ->
  Voyzes.initialize()
  
