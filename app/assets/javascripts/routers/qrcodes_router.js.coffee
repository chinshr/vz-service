class Qscribe.Routers.Qrcodes extends Backbone.Router
  routes:
    '' : 'showManageImages'
    'qrcode/add' : 'addNewImage'

  showManageImages: -> 
    @collection = new Qscribe.Collections.Qrcodes()
    @collection.fetch() 
    view = new Qscribe.Views.QrcodesIndex collection: @collection
    $('#container-app').html view.render().el

  addNewImage : ->
    view = new Qscribe.Views.QrcodesAddView
    $('#container-app').html view.render().el