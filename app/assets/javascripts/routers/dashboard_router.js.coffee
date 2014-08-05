class App.Routers.Dashboard extends Backbone.Router
  routes:
    '' : 'default'

  default: -> 
    @collection = new App.Collections.Uploads()
    # @collection.fetch() 
    view = new App.Views.UploadsIndex collection: @collection
    $('#upload-app').html view.render().el
      
