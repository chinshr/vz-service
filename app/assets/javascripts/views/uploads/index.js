App.Views.UploadsIndex = Backbone.View.extend({
  template: JST['uploads/index'],

  events: {
    'drop #drop-box': 'dropFiles',
    'change input#files': 'addFiles',
    'click button#files-proxy': 'trigger',
    'mouseenter #drop-box': 'hover',
    'mouseleave #drop-box': 'hover'
  },
  
  // Listen for newly added models and render a view for each
  initialize: function() {
    this.listenTo(this.collection, 'add', this.addUpload);
    this.listenTo(this.collection, 'reset', this.addAll);
    
    this.progressViews = {};
  },

  render: function() {
    this.$el.html(this.template);
    this.addAll();
    return this;
  },

  hover: function(e) {
    if (e.type === 'mouseenter') {
      $(e.currentTarget).addClass('hover');
    } else {
      $('body').removeClass('hover');
      $(e.currentTarget).removeClass('hover');
    }
  },
  
  trigger: function() {
    $('#files').trigger('click');
  },
            
  // Instantiate and render new views for models added to the collection
  // This is the view that will be listening to the 'upload:progress' event, 
  // and can also allow the user to cancel the upload
  addUpload: function(model, response) {
    var view;
    if (!_.isEmpty(model.attributes)) {
      if (model.attributes.editable) {
        view = new App.Views.UploadsEdit({model: model});
        this.$('#uploaded-files').before(view.render({name: 'edit-file-name.a'}).el);
      } else {
        view = new App.Views.UploadsShow({model: model});
        this.$('#uploaded-files').append(view.render({name: 'show-file-name.a'}).el);
      }
      return this.progressViews[model.cid] = view;
    }
  },

  addAll: function() {
    this.collection.each(this.addUpload, this);
  },
  
  addFiles: function(e) {
    if ($(e.target).val() === '') {
      return;
    }

    return this.uploadToS3({
      files_dropped: false,
      file_dom_selector: '#files'
    });
  },

  dropFiles: function(e) {
    e.originalEvent.preventDefault();

    if (e.dataTransfer === null) {
      return;
    }

    return this.uploadToS3({
      files_dropped: true,
      file_list: e.originalEvent.dataTransfer.files
    });
  },

  dropzone: function(e) {
    e.originalEvent.preventDefault();
    e.originalEvent.stopPropagation();
  },

  uploadToS3: function(options) {
    var newUploads, s3upload;
    newUploads = {};
    return s3upload = new S3Upload({
      files_dropped: options.files_dropped,
      file_list: options.file_list,
      file_dom_selector: options.file_dom_selector,
      s3_sign_put_url: 'api/account/uploads/signput.json',
      onProgress: (function(_this) {
        return function(xhr, file, percent, message) {
          var upload;
          if (percent === 0) {
            upload = new App.Models.Upload({
              file_name: file.name,
              s3_url: '',
              file_type: file.type,
              file_size: parseFloat(file.size),
              type: "audio",
              locale: _this.$("#file-locale").val() || "en-US",
              privacy: _this.$("#file-privacy").val() || "public",
              editable: true
            });
            newUploads[file.size] = upload;
            return _this.collection.add(upload);
          } else {
            upload = newUploads[file.size];
            if (upload) {
              return upload.trigger('upload:progress', {
                percent: percent,
                message: message,
                xhr: xhr
              });
            }
          }
        };
      })(this),
      
      onAbort: (function(_this) {
        return function(file, message) {
          var upload;
          upload = newUploads[file.size];
          upload.destroy();
          delete newUploads[file.size];
          return _this.$('input#files').replaceWith("<input id='files' type='file' name='files[]' multiple />");
        };
      })(this),
      
      onFinishS3Put: (function(_this) {
        return function(public_url, file) {
          var upload;
          upload = newUploads[file.size];
          return upload.save({s3_url: public_url});
        };
      })(this),
      
      onError: (function(_this) {
        return function(file, status) {
          var upload;
          console.log('Upload error: ', status);
          upload = newUploads[file.size];
          upload.destroy();
          return delete newUploads[file.size];
        };
      })(this)
    });
  }
});