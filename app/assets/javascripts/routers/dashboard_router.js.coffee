class App.Routers.Dashboard extends Backbone.Router
  routes:
    '' : 'default'

  default: -> 
    @collection = new App.Collections.Uploads()
    @collection.fetch({data: $.param({'sort_order': {'created_at': 'desc'}})}) 
    view = new App.Views.UploadsIndex collection: @collection
    $('#file-uploads').html view.render().el
