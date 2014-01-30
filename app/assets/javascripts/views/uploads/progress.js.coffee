class Qscribe.Views.UploadsProgress extends Backbone.View
  template: JST['uploads/progress']
  events: 
    'click .cancel' : 'onCancelUpload'
    'submit' : 'onFormSubmit'
    'keyup input': 'fieldChanged'
    'change select': 'selectionChanged'
  
  render: ->
    @$el.html @template @model.attributes
    Backbone.Validation.bind(@)
    @

  initialize: () ->
    @interval = null
    @listenTo(@model, 'upload:progress', @onUploadProgress)
    @listenTo(@model, 'destroy', @destroy)
    @listenToOnce(@model, 'sync', @onAfterCreate)

  onUploadProgress: (data) ->
    console.log data.percent
    console.log data.message
    @$('.progress .progress-bar').css('width', "#{data.percent}%")
    @$('.message').html(data.message);

    if data.percent == 100
      @_xhr = null
    else if !@_xhr
      # Else if @_xhr is not yet defined, save a reference to it
      @_xhr = data.xhr

  onCancelUpload: (e) ->
    # Leverage the saved xhr reference to abort() the upload
    if @_xhr
      @_xhr.abort()
    @stop()
    @$(".progress-panel").remove()
    
  onAfterCreate: (e) ->
    # fill form
    @$("input[name='upload[title]']").val(@model.attributes.title)
    @$("select[name='upload[locale]']").val(@model.attributes.locale)
    @$("select[name='upload[privacy]']").val(@model.attributes.privacy)
    
    @$('form input, form textarea, form button').removeAttr("disabled")
    @$(".form-fields").show()
    
    @$('.message').html(@model.message())
    @ping()
    
  onFormSubmit: (e) ->
    e.originalEvent.preventDefault()
    form = $(e.target)
    data = {}
    
    _.map form.serializeArray(), (n) ->
      key = n['name'].match(/\[(.+)\]/)
      data[key[1]] = n['value'] if key.length > 1
    @model.set(data)

    if @model.isValid(true)
      @$(".btn").button("loading")
      @model.sync 'update', @model,
        success: () =>
          @$(".btn").button("reset")
        error: () =>
          @$(".btn").button("reset")
    
  ping: ->
    @interval = setInterval =>
        @poll()
      , 2500

  stop: ->
    window.clearInterval(@interval)

  poll: ->
    @model.sync 'read', @model,
      success: (data) =>
        @model.set("progress", data.upload.progress)
        @model.set("status", data.upload.status)
      error: (model) =>
        console.log "error fetching upload ID = #{@data.upload.id}"
    
    @$('.message').html(@model.message())
    @$('.alert-slug-link').html("<a href=\"#{@model.attributes.slug}\" target=\"_blank\">http://voyz.es/#{@model.attributes.slug}</a>")

    @$('.progress .progress-bar').css('width', "#{@model.attributes.progress}%")

    # show progressbar motion
    if @model.hasProgress()
      @$('.progress').addClass('active')
    else
      @$('.progress').removeClass('active')

    # change to green status label when finished
    if @model.hasFinished()
      @$('.status').removeClass('label-info').addClass('label-success')
    else
      @$('.status').removeClass('label-success').addClass('label-info')
      
    # change progress bar color to green when transcribing
    if !@$('.progress .progress-bar').hasClass('progress-bar-success')
      @$('.progress .progress-bar').removeClass('progress-bar-info')
      @$('.progress .progress-bar').addClass('progress-bar-success')

  fieldChanged: (e) ->
    field = $(e.currentTarget)
    data = {}
    if key = field.attr('name').match(/\[(.+)\]/)[1]
      data[key] = field.val()
      @model.set data
      #@model.isValid key
      @model.validate()
            
  selectionChanged: (e) ->
    field = $(e.currentTarget)
    data  = {}
    if key = field.attr('name').match(/\[(.+)\]/)[1]
      data[key] = field.val()
      @model.set(data)
      @model.validate()
