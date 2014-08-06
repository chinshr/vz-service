window.App =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: -> 
    new App.Routers.Dashboard()
    Backbone.history.start()

$(document).ready ->
  App.initialize()
  
