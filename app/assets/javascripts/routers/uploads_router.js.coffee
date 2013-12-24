class Qscribe.Routers.Uploads extends Backbone.Router
  routes:
    '' : 'showIndex'

  showIndex: -> 
    @collection = new Qscribe.Collections.Uploads()
    # @collection.fetch() 
    view = new Qscribe.Views.UploadsIndex collection: @collection
    $('#upload-app').html view.render().el
      
      