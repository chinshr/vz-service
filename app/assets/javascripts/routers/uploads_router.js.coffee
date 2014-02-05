class Voyzes.Routers.Uploads extends Backbone.Router
  routes:
    '' : 'showIndex'

  showIndex: -> 
    @collection = new Voyzes.Collections.Uploads()
    @collection.fetch() 
    view = new Voyzes.Views.UploadsIndex collection: @collection
    $('#upload-app').html view.render().el
      
      