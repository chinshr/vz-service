class App.Routers.Dashboard extends Backbone.Router
  routes:
    '' : 'default'

  default: -> 
    @collection = new App.Collections.Uploads()
    @collection.fetch() 
    view = new App.Views.Dashboard collection: @collection
    $('#uploaded-files').html view.render().el

