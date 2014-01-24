class Qscribe.Views.UploadsIndex extends Backbone.View
  template: JST['uploads/index']

  events:
    'dragenter #drop-box': 'doNothing'
    'dragover #drop-box': 'doNothing'
    'drop #drop-box': 'onDrop'
    'change input#files': 'onChangeFiles'
  
  render: ->
    @$el.html @template
    @

  # Listen for newly added models and render a view for each
  initialize: () ->
    @listenTo @collection, 'add', @onAddProgress
    @progressViews = {}
          
  # Instantiate and render new views for models added to the collection
  # This is the view that will be listening to the 'upload:progress' event, and can also allow the user to cancel the upload
  onAddProgress: (model, response) ->
    progressView = new Qscribe.Views.UploadsProgress(model: model)
    @$('#file-uploads').append(progressView.render({name: "test-file-name.a"}).el)
    @progressViews[model.cid] = progressView

  onChangeFiles: (e) ->
    return if $(e.target).val() == ''

    @uploadToS3
      files_dropped: false,
      file_dom_selector: '#files'

  onDrop: (e) ->
    e.originalEvent.preventDefault()
    
    return if e.dataTransfer == null

    @uploadToS3
      files_dropped: true,
      file_list: e.originalEvent.dataTransfer.files

  doNothing: (e) ->
    e.originalEvent.preventDefault()
    e.originalEvent.stopPropagation()

  # Instantiation of a new S3Upload with custom callbacks
  uploadToS3: (options) ->
    # We create an object to store the newly created models for reference in progress and abort callbacks
    newUploads = {}
    s3upload = new S3Upload
      # files_dropped and file_list are only necessary for handling drag and drop uploads, which we'll address later
      files_dropped: options.files_dropped,
      file_list: options.file_list,
      file_dom_selector: options.file_dom_selector,
      s3_sign_put_url: 'api/uploads/signput.json',

      onProgress: (xhr, file, percent, message) =>
        # Create a new Attachment model for the file which has just started uploading, 
        # otherwise trigger an 'upload:progress' event on the model which a view can listen for
        if percent == 0
          upload = new Qscribe.Models.Upload
            file_name: file.name,
            s3_url: '',
            file_type: file.type,
            file_size: parseFloat(file.size),
            type: "audio",
            locale: @$("#file-locale").val() || "en-US",
            privacy: @$("#file-privacy").val() || "public"
          # Key on file.size for uniqueness
          newUploads[file.size] = upload
          # Add the model to the Backbone collection, which will trigger an 'add' event
          @collection.add(upload)
        else
          upload = newUploads[file.size]
          if upload
            upload.trigger('upload:progress', { percent: percent, message: message, xhr: xhr })

      onAbort: (file, message) =>
        upload = newUploads[file.size]
        upload.destroy()
        delete newUploads[file.size]
        # Must replace old input type=file. for some reason, it doesn't clear the value
        @$('input#files').replaceWith("<input id='files' type='file' name='files[]' multiple />")

      onFinishS3Put: (public_url, file) =>
        # Grab the attachment model and update it with the final url
        # Also note that the model has not yet been saved, so the backend would be unaware of a cancelled upload
        upload = newUploads[file.size]
        upload.save({ s3_url: public_url })

      onError: (file, status) =>
        console.log('Upload error: ', status)
        upload = newUploads[file.size]
        upload.destroy()
        delete newUploads[file.size]