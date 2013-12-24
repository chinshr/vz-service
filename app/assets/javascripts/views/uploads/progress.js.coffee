class Qscribe.Views.UploadsProgress extends Backbone.View
  template: JST['uploads/progress']
  events: 
    'click .cancel' : 'onCancelUpload'
  
  render: ->
    @$el.html @template
    @

  initialize: () ->
    @listenTo(@model, 'upload:progress', @onUploadProgress)
    @listenTo(@model, 'destroy', @destroy)

  onUploadProgress: (data) ->
    @$('.progress .progress-bar').css('width', "#{data.percent}%")

    if data.percent == 100
      # If the upload is complete, remove the progress bar and cancel button
      @$('.progress, .cancel').remove()
      @_xhr = null
    else if !@_xhr
      # Else if @_xhr is not yet defined, save a reference to it
      @_xhr = data.xhr

  onCancelUpload: (e) ->
    # Leverage the saved xhr reference to abort() the upload
    if @_xhr
      @_xhr.abort()