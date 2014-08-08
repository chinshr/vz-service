# TODO remove, old router
class App.Routers.Uploads extends Backbone.Router
  routes:
    '' : 'showIndex'

  showIndex: -> 
    @collection = new App.Collections.Uploads()
    # @collection.fetch() 
    view = new App.Views.UploadsIndex collection: @collection
    $('#upload-app').html view.render().el
      
      