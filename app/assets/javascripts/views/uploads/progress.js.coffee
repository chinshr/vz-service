class Qscribe.Views.UploadsProgress extends Backbone.View
  template: JST['uploads/progress']
  events: 
    'click .cancel' : 'onCancelUpload'
  
  render: ->
    @$el.html @template @model.attributes
    @

  initialize: () ->
    @listenTo(@model, 'upload:progress', @onUploadProgress)
    @listenTo(@model, 'destroy', @destroy)

  onUploadProgress: (data) ->
    console.log data.percent
    console.log data.message
    @$('.progress .progress-bar').css('width', "#{data.percent}%")
    @$('.message').html(data.message);

    if data.percent == 100
      @$('.progress').removeClass('active')
      @$('form input, form textarea, form button').removeAttr("disabled")
      @_xhr = null
    else if !@_xhr
      # Else if @_xhr is not yet defined, save a reference to it
      @_xhr = data.xhr

  onCancelUpload: (e) ->
    # Leverage the saved xhr reference to abort() the upload
    if @_xhr
      @_xhr.abort()
    @$(".progress-panel").remove()