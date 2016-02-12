App.Views.PopoversImageUpload = App.Views.PopoverBase.extend({
  template: JST['popovers/image_upload'],

  events: {
    'click .btn-cancel': "cancel"
  },

  initialize: function(options) {
    App.Views.PopoverBase.prototype.initialize.call(this, options); // super
    _.bindAll(this, "update", "refreshUploadCallback", "cancel", "initListeners");

    this.model     = null;
    this.xhr       = null;
    this.callbacks = options.callbacks || {};

    this.initPubnub();
    this.uploadToS3(options);
  },

  cancel: function(event) {
    var _this = this;
    if (this.hasUploadProgress()) {
      setTimeout(function () {
        if (_this.xhr) {
          _this.xhr.abort();
        } else {
          _this.cancel();
        }
      }, 20);
    } else if (this.model && this.hasProgress()) {
      var options = {patch: true};
      if (_this.callbacks.canceled) {
        _.extend(options, {
          success: _this.callbacks.canceled()
        });
      }
      this.model.save({event: "stop"}, options);
    } else {
      // maybe finished in the meantime?
      _this.hide();
    }
  },

  update: function() {
    this.updateStatus();
    this.updateProgress();
    this.handleNextStep();
  },

  render: function() {
    this.holder  = this.holder || this.parent.$(".btn-image-upload");
    this.popover = this.holder.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: this.placement,
      template: '<div class="popover image-upload-popover" id="image-upload-popover"><div class="popover-content"></div></div>',
      content: this.$el.html(this.template(_.extend({
        progress: 0
      }, this.model ? this.model.attributes : {})))
    }).on('shown.bs.popover', this.setup)
      .on('hidden.bs.popover', this.teardown)
      .data("bs.popover");

    this.holder.on('click', (function(_this) {
      return function(e) {
        e.stopPropagation();
        e.preventDefault();
        _this.holder.tooltip('hide');
        /* close all other popovers except this */
        _this.holder.not(this).popover('hide');
        // _this.popover.toggle();
      };
    })(this));

    return this;
  },

  uploadToS3: function(options) {
    return new S3Upload({
      dropped: options.dropped,
      files: options.files,
      selector: options.selector,
      s3SignURL: 'api/account/uploads/signed_s3_put.json',

      // progress
      onProgress: (function(_this) {
        return function(xhr, file, percent, status) {
          if (!xhr && percent === 0) {
            _this.model = new App.Models.Upload({
              type: 'Upload::ImageUpload',
              ingestable_id: _this.parent.model.attributes.document_id,
              ingestable_type: "Document",
              file_name: file.name,
              file_type: file.type,
              file_size: parseFloat(file.size),
              locale: _this.parent.model.locale
            });
            _this.initListeners();
            return _this.model;
          } else {
            if (_this.model) {
              _this.xhr = xhr;
              return _this.model.set({
                progress: percent,
                state: status
              });
            }
          }
        };
      })(this),

      // abort
      onAbort: (function(_this) {
        return function(file, status) {
          if (_this.callbacks.canceled) {
            return _this.callbacks.canceled(file, status);
          }
        };
      })(this),

      // finished
      onFinishS3Put: (function(_this) {
        return function(publicUrl, file) {
          if (_this.model) {
            _this.xhr = null;
            return _this.model.save({source_url: publicUrl}, {
              success: function(model, response) {
                console.log(model, response);
              },
              error: function(model, response) {
                console.log(model, response);
              }
            });
          }
        };
      })(this),

      // error
      onError: (function(_this) {
        return function(file, status) {
          if (_this.model) {
            return _this.model.set({state: status});
          }
        };
      })(this)
    });
  },

  initListeners: function() {
    if (this.model) {
      this.listenTo(this.model, 'change', this.update);
    }
  },

  translateStatus: function(state) {
    if (this.hasUploadProgress()) {
      // uploading
      switch (state) {
        // upload states
        case 'uploading':
        return "Uploading...";
        case 'completed':
        return "Processing...";
        case 'completing':
        return "Upload finishing.";
        case 'error':
        return "Upload error.";
      }
    } else {
      // processing
      switch (state) {
        // ingest states
        case 'completed':  // spillover from uploading
        case 'starting':
        case 'started':
        return "Processing..."
        case 'finished':
        return "Processing finished."
        case 'stopping':
        return "Processing stopping."
        case 'stopped':
        return "Processing stopped."
        case 'resetting':
        return "Processing resetting."
        case 'reset':
        return "Processing reset."
        default:
        return "Unknown status (" + state + ").";
      }
    }
  },

  updateProgress: function() {
    var percent = 0,
      progressBarEl = this.$('.progress .progress-bar');
      progressEl = this.$('.progress');

    if (this.model.attributes.progress) {
      if (this.hasProgress() && !this.hasUploadProgress()) {
        percent = 50;
      }
      percent += (this.model.attributes.progress / 2);
      progressBarEl.css('width', "" + percent + "%");
    }

    progressBarEl
      .removeClass('progress-bar-info')
      .removeClass('progress-bar-success')
      .removeClass('progress-bar-warning')
      .removeClass('progress-bar-danger');

    // colors depending on status
    if ((this.model && this.model.hasFinished()) || (this.model.attributes.status === 'completed')) {
      progressBarEl.addClass('progress-bar-success');
    } else if ((this.model && this.model.hasStopped()) || (this.model.attributes.status === 'error')) {
      progressBarEl.addClass('progress-bar-danger');
    } else {
      progressBarEl.addClass('progress-bar-warning');
    }

    // animated striped progress or not
    if (this.hasProgress()) {
      progressEl.addClass('active').addClass('progress-striped');
    } else {
      progressEl.removeClass('active').removeClass('progress-striped');
    }
  },

  updateStatus: function() {
    var uploadStatusEl = this.$('.upload-status');

    uploadStatusEl
      .removeClass('danger')
      .removeClass('warning')
      .removeClass('info')
      .removeClass('success');

    if (this.model.attributes.state === 'error') {
      uploadStatusEl.addClass('danger');
    }

    uploadStatusEl.html(this.translateStatus(this.model.attributes.state));
    return uploadStatusEl;
  },

  handleNextStep: function() {
    if (this.model.attributes.state === "finished" && this.callbacks.finished) {
      return this.callbacks.finished(this.model);
    } else if(this.model.attributes.state === "stopped" && this.callbacks.stopped) {
      return this.callbacks.stopped(this.model);
    }
  },

  hasProgress: function() {
    return this.hasUploadProgress() || this.model.hasProgress();
  },

  hasUploadProgress: function() {
    return !!this.xhr;
  },

  initPubnub: function() {
    var _this = this,
      currentRefreshUploadSequence;

    this.refreshUploadQueue = [];

    this.pubnub = PUBNUB.init({
      publish_key: VZ.config.pubnub.publish_key,
      subscribe_key: VZ.config.pubnub.subscribe_key,
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
        _this.model.set(data);
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
    if (message.command === "refresh_upload" &&
      message.data && message.data.upload_type === "Upload::ImageUpload" &&
      message.data.upload_uid === this.model.attributes.uid) {
      console.log("-> message: ", message);
      this.refreshUploadQueue.push(message.data);
    }
  },

  destroy: function() {
    this.clearUploadQueueTimer();
    return App.Views.PopoverBase.prototype.destroy.call(this); // super
  }

});