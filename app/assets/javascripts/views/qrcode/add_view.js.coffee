class Qscribe.Views.QrcodesAddView extends Backbone.View
  template: JST['qrcodes/add']
  render: ->
    @$el.html @template
    @uploadQrcode()
    @

  uploadQrcode: =>
    @$el.fileupload
    add: (e, data)->
      $('#qrcode_image').hide()
      $("#fileupload-loading").html 'Cargando...'
      data.submit()

    formData: [
      name: 'authenticity_token'
      value: $("meta[name=\'csrf-token\']").attr('content')
    ]

    done: (e, data) ->
      window.location = '/'