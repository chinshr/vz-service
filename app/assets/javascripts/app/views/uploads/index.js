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
    _.bindAll(this, "initSourceModal", "initUnload",
      "initDropTarget", "addHover", "removeHover", "trigger",
      "addUploadView", "addAll", "addFiles", "dropFiles",
      "dropzone", "uploadToS3", "statusMessage", "initMailTo",
      "refreshUploadCallback", "refreshLayout");

    this.listenTo(this.collection, 'add', this.addUploadView);
    this.listenTo(this.collection, 'reset', this.addAll);
    this.progressViews = {};
    this.initPubnub();
  },

  render: function() {
    var _this = this;
    this.$el.html(this.template);

    this.addAll();

    _.defer(function() {
      _this.initIsotope();
      _this.initDropTarget();
      _this.initUnload();
      _this.initSourceModal();
      _this.initMailTo();
      _this.grid.imagesLoaded(function() {
        _this.refreshLayout();
        _this.show();
      });
    });
    return this;
  },

  show: function() {
    $('#content-loading').hide();
  },

  showPageError: function() {
    $('#loading').hide();
    $('#load-error').show();
  },

  // Instantiate and render new views for models added to the collection
  // This is the view that will be listening to the 'upload:progress' event,
  // and can also allow the user to cancel the upload
  addUploadView: function(model, response) {
    var _this = this,
      view,
      grid = this.$('.browser-grid'),
      item = $('<div class="grid-item col-lg-2 col-md-3 col-sm-6 col-xs-12" data-type="' + (model.attributes.id ? 'instance' : 'new-instance') + '"></div>');

    if (!_.isEmpty(model.attributes)) {
      if (model.attributes.editable) {
        view = new App.Views.UploadsEdit({model: model, parent: this});
        item.append(view.render({name: 'edit-file-name.a'}).el);
      } else {
        view = new App.Views.UploadsShow({model: model, parent: this});
        item.append(view.render({name: 'show-file-name.a'}).el);
      }

      _this.initIsotope();

      // Isotope add items:
      // http://isotope.metafizzy.co/v1/docs/adding-items.html
      grid.imagesLoaded(function() {
        grid.isotope('insert', item);
        grid.isotope('reveal', grid.data('isotope').items);
      });

      return this.progressViews[model.cid] = view;
    }
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

  addAll: function() {
    this.collection.each(this.addUploadView, this);
  },

  addFiles: function(e) {
    if ($(e.target).val() === '') {
      return;
    }

    return this.uploadToS3({
      dropped: false,
      selector: '#files'
    });
  },

  dropFiles: function(event) {
    event.originalEvent.preventDefault();

    if (event.dataTransfer === null) {
      return;
    }

    this.removeHover(event);

    return this.uploadToS3({
      dropped: true,
      files: event.originalEvent.dataTransfer.files
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
      dropped: options.dropped,
      files: options.files,
      selector: options.selector,
      s3SignURL: 'api/account/uploads/signed_s3_put.json',

      onProgress: (function(_this) {
        return function(xhr, file, percent, status) {
          var upload;
          if (!xhr && percent === 0) {
            upload = new App.Models.Upload({
              file_name: file.name,
              file_type: file.type,
              file_size: parseFloat(file.size),
              locale: _this.$("#file-locale").val() || "en-US",
              privacy: "private",
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
  },

  initIsotope: function() {
    this.grid = this.$('.browser-grid');

    this.grid.isotope({
      itemSelector: '.grid-item',
      layoutMode: 'masonry',
      percentPosition: false,
      isInitLayout: true,
      animationEngine: 'best-available',
      masonry: {
        columnWidth: 0
      },
      // sort by number
      sortBy: ['type', 'number'],
      sortAscending : false,
      getSortData: {
        'type': '[data-type]',
        'number': function (elem) {
          return parseInt($(elem).find('.number').text(), 10);
        }
      }
    });

    return this.grid;
  },

  refreshLayout: function() {
    if (this.grid.data('isotope')) {
      this.grid.isotope('layout');
    }
  },

  initPubnub: function() {
    var _this = this,
      currentRefreshUploadSequence;

    this.refreshUploadQueue = [];

    this.pubnub = PUBNUB.init({
      publish_key: VZ.config.pubnub.publish_key,
      subscribe_key: VZ.config.pubnub.subscribe_key,
      // uuid: App.currentUser.attributes.username,
      // heartbeat: 120,
      // heartbeat_interval: 30,
      ssl: VZ.isSSL()
    });

    this.pubnub.subscribe({
      channel: this.pubnubChannel(),
      message: this.refreshUploadCallback,
      state: App.currentUser.attributes
    });

    this.refreshUploadQueueInterval = setInterval(function() {
      var data = _this.refreshUploadQueue.pop();

      if (data && (!currentRefreshUploadSequence || data.sequence > currentRefreshUploadSequence)) {
        currentRefreshUploadSequence = data.sequence;
        var _model = _this.collection.find(function(m) { return m.attributes.uid === data.upload_uid; });
        if (!!_model) {
          // existing upload
          _model.set(data);
        } else {
          // new upload
          _model = new App.Models.Upload({id: data.upload_id});
          _model.fetch({
            success: function() {
              _this.collection.add(_model);
            }
          });
        }
      }
    }, 100);
  },

  clearUploadQueueTimer: function() {
    if (this.refreshUploadQueueInterval) {
      return clearInterval(this.refreshUploadQueueInterval);
    }
  },

  pubnubChannel: function() {
    return "vz-user-" + App.currentUser.attributes.uid;
  },

  refreshUploadCallback: function(message) {
    if (message.command === "refresh_upload" && message.data && message.data.upload_type === "Upload::MediaUpload") {
      console.log("-> message: ", message);
      this.refreshUploadQueue.push(message.data);
    }
  }

});