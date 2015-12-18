App.Views.UploadsIndex = Backbone.View.extend({
  template: JST['uploads/index'],

  events: {
    'drop #drop-box': 'dropFiles',
    'change input#files': 'addFiles',
    'click button#files-proxy': 'trigger',
    'mouseenter #drop-box': 'addHover',
    'mouseleave #drop-box': 'removeHover',
    'change #file-locale': 'initMailTo',
    'click button#upload-source': 'openSourceModal'
  },

  // Listen for newly added models and render a view for each
  initialize: function() {
    this.listenTo(this.collection, 'add', this.addUploadView);
    this.listenTo(this.collection, 'reset', this.addAll);
    this.progressViews = {};
    _.bindAll(this, "initSourceModal", "initUnload",
      "initDropTarget", "addHover", "removeHover", "trigger",
      "addUploadView", "addAll", "addFiles", "dropFiles",
      "dropzone", "uploadToS3", "statusMessage", "initMailTo");
  },

  render: function() {
    this.$el.html(this.template);
    _.defer((function(_this) {
      return function() {
        _this.initDropTarget();
        _this.initUnload();
        _this.initSourceModal();
        _this.initMailTo();
      }
    })(this));

    this.addAll();
    return this;
  },

  views: function() {
    return _(this.progressViews).pairs().filter(_.last).map(_.last);
  },

  initUnload: function() {
    var _this = this;
    var confirm = function(event) {
      if (_.any(_this.views(), function(v) { return v.model.isUploading() })) {
        return 'All uploads will be canceled if you leave this page.';
      }
    };
    window.onbeforeunload = confirm;
  },

  initDropTarget: function() {
    var dropTarget = $('#drop-box'),
      body = $('body'),
      showDrag = false,
      timeout = -1,
      _this = this;

    body.on('dragenter', function (event) {
      event.originalEvent.preventDefault();
      event.originalEvent.stopPropagation();
      console.log("=> dragenter");
      body.addClass('hover');
      dropTarget.addClass('hover');
      showDrag = true;
    }).on('dragover', function(event){
      event.originalEvent.preventDefault()
      event.originalEvent.stopPropagation()
      showDrag = true;
    }).on('dragleave', function (event) {
      event.originalEvent.preventDefault()
      event.originalEvent.stopPropagation()
      showDrag = false;
      clearTimeout( timeout );
      timeout = setTimeout(function() {
        if (!showDrag) {
          dropTarget.removeClass('hover');
          body.removeClass('hover');
        }
      }, 200 );
    });
  },

  initSourceModal: function() {
    return this.sourceModal = new App.Views.UploadsSourceModal({
      parent: this
    });
  },

  addHover: function(event) {
    if (event) {
      $(event.currentTarget).addClass('hover');
    }
  },

  removeHover: function(event) {
    if (event) {
      $(event.currentTarget).removeClass('hover');
    }
    $('body').removeClass('hover');
  },

  trigger: function() {
    $('#files').trigger('click');
  },

  // Instantiate and render new views for models added to the collection
  // This is the view that will be listening to the 'upload:progress' event,
  // and can also allow the user to cancel the upload
  addUploadView: function(model, response) {
    var view;
    if (!_.isEmpty(model.attributes)) {
      if (model.attributes.editable) {
        view = new App.Views.UploadsEdit({model: model});
        this.$('#uploaded-files').append(view.render({name: 'edit-file-name.a'}).el);
      } else {
        view = new App.Views.UploadsShow({model: model});
        this.$('#uploaded-files').append(view.render({name: 'show-file-name.a'}).el);
      }
      return this.progressViews[model.cid] = view;
    }
  },

  addAll: function() {
    this.collection.each(this.addUploadView, this);
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

  dropFiles: function(event) {
    event.originalEvent.preventDefault();

    if (event.dataTransfer === null) {
      return;
    }

    this.removeHover(event);

    return this.uploadToS3({
      files_dropped: true,
      file_list: event.originalEvent.dataTransfer.files
    });
  },

  dropzone: function(event) {
    event.originalEvent.preventDefault();
    event.originalEvent.stopPropagation();
  },

  uploadToS3: function(options) {
    var newUploads = {},
      s3upload;

    return s3upload = new S3Upload({
      files_dropped: options.files_dropped,
      file_list: options.file_list,
      file_dom_selector: options.file_dom_selector,
      s3_sign_put_url: 'api/account/uploads/sign_s3.json',

      onProgress: (function(_this) {
        return function(xhr, file, percent, status) {
          var upload;
          if (!xhr && percent === 0) {
            upload = new App.Models.Upload({
              file_name: file.name,
              file_type: file.type,
              file_size: parseFloat(file.size),
              locale: _this.$("#file-locale").val() || "en-US",
              privacy: _this.$('.group-file-privacy input[type=radio]:checked').val() || "unlisted",
              editable: true,
              metadata: {"te_name": VZ.query.te}
            });
            newUploads[file.size] = upload;
            return _this.collection.add(upload);
          } else {
            upload = newUploads[file.size];
            if (upload) {
              return upload.trigger('upload:progress', {
                percent: percent,
                message: _this.statusMessage(status),
                xhr: xhr
              });
            }
          }
        };
      })(this),

      onAbort: (function(_this) {
        return function(file, status) {
          var upload;
          upload = newUploads[file.size];
          upload.destroy();
          delete newUploads[file.size];
          return _this.$('input#files').replaceWith("<input id='files' type='file' name='files[]' multiple />");
        };
      })(this),

      onFinishS3Put: (function(_this) {
        return function(publicUrl, file) {
          var upload = newUploads[file.size];
          if (upload) {
            return upload.save({source_url: publicUrl});
          }
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
  },

  statusMessage: function(state) {
    switch (state) {
      case 'starting':
      return "Upload starting.";
      case 'completed':
      return "Upload completed.";
      case 'completing':
      return "Upload finalizing.";
      case 'uploading':
      return "Uploading.";
      default:
      return "Unknown upload state";
    }
  },

  initMailTo: function() {
    var locale = $("#file-locale").val().toLowerCase();
    this.$('.btn-email-upload').text("my+" + locale + "@voyz.es");
    this.$('.btn-email-upload').attr('href', this.mailtoHref);
  },

  mailtoHref: function() {
    var locale = $("#file-locale").val().toLowerCase(),
      text = $("#file-locale option:selected").text() + " (" + $("#file-locale").val() + ")";
    var href = "mailto:my+" + locale + "@voyz.es" +
      "?subject=Change%20title" +
      "&body=—%0DAttach audio files to transcribe for " + text + ". Change title and add description above the line.";
    return href
  },

  openSourceModal: function() {
    this.sourceModal.render().show();
  }

});