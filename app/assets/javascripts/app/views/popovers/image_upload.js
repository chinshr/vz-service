App.Views.PopoversImageUpload = App.Views.PopoverBase.extend({
  template: JST['popovers/image_upload'],

  events: {
    'click .btn-cancel': "cancel"
  },

  initialize: function(options) {
    App.Views.PopoverBase.prototype.initialize.call(this, options); // super
    _.bindAll(this, "setup", "teardown", "progress", "refreshUploadCallback", "cancel");

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

  progress: function(data) {
    this.updateStatus(data);
    this.updateProgress(data);
    this.handleNextStep(data);
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

    // close popover when another one is opened
    this.holder.on('click', (function(_this) {
      return function(e) {
        e.stopPropagation();
        _this.holder.tooltip('hide');
        /* close all other popovers except this */
        _this.holder.not(this).popover('hide');
        $('.btn-more, .btn-popover, [data-rel="popover"], .popover').not(_this.holder).popover('hide');
        _this.popover.toggle();
      };
    })(this));

    // ???
    $(document).on('click', (function(_this) {
      return function(e) {
        if (!$(e.target).is(_this.holder) && _this.holder.find($(e.target)).length === 0 && $(".btn-more").find($(e.target)).length === 0) {
          _this.hide();
        }
      }
    })(this));

    return this;
  },

  setup: function() {
    this.holder.tooltip('disable');
  },

  teardown: function() {
    this.holder.tooltip('enable');
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
            _this.listenTo(_this.model, 'upload:image:progress', _this.progress);
            return _this.model;
          } else {
            if (_this.model) {
              _this.xhr = xhr;
              return _this.model.trigger('upload:image:progress', {
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
            return _this.model.trigger('upload:image:progress', {
              state: status
            });
          }
        };
      })(this)
    });
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

  updateProgress: function(data) {
    var percent = 0,
      progressBarEl = this.$('.progress .progress-bar');
      progressEl = this.$('.progress');

    if (data && data.progress) {
      if (this.hasProgress() && !this.hasUploadProgress()) {
        percent = 50;
      }
      percent += (data.progress / 2);
      progressBarEl.css('width', "" + percent + "%");
    }

    progressBarEl
      .removeClass('progress-bar-info')
      .removeClass('progress-bar-success')
      .removeClass('progress-bar-warning')
      .removeClass('progress-bar-danger');

    // colors depending on status
    if ((this.model && this.model.hasFinished()) || (data && data.status === 'completed')) {
      progressBarEl.addClass('progress-bar-success');
    } else if ((this.model && this.model.hasStopped()) || (data && data.status === 'error')) {
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

  updateStatus: function(data) {
    var uploadStatusEl = this.$('.upload-status');

    uploadStatusEl
      .removeClass('danger')
      .removeClass('warning')
      .removeClass('info')
      .removeClass('success');

    if (data.state === 'error') {
      uploadStatusEl.addClass('danger');
    }

    uploadStatusEl.html(this.translateStatus(data.state));
    return uploadStatusEl;
  },

  handleNextStep: function(data) {
    if (data && data.state === "finished" && this.callbacks.finished) {
      return this.callbacks.finished(data);
    } else if(data && data.state === "stopped" && this.callbacks.stopped) {
      return this.callbacks.stopped(data);
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
      uuid: App.currentUser.attributes.username,
      heartbeat: 120,
      heartbeat_interval: 30,
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
        _this.progress(data);
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