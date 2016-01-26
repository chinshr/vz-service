App.Views.UploadsBase = Backbone.View.extend({
  events: {
    'mouseenter .show-panel': 'hover',
    'mouseleave .show-panel': 'hover'
  },

  initialize: function(options) {
    _.bindAll(this, "render", "remove", "hover", "trigger", "update", "updatePrivacy");
    this.parent = options.parent;
    this.listenTo(this.model, 'upload:progress', this.onUploadProgress);
    this.listenTo(this.model, 'destroy', this.remove);
    this.listenTo(this.model, 'change', this.update);
  },

  render: function(attributes) {
    var template = this.template(_.extend(this.model.attributes, {
      status_message: this.model.statusMessage(),
      events: this.permissibleEvents(),
      // model: this.model,
      thumb_aspect_ratio_1_url: this.model.imageSource(1),
      thumb_bg_color: this.model.rgbaColor()
    }));

    this.setElement(template);

    _.defer((function(_this) {
      return function() {
        _this.initPublishPopover().render();
        _this.initSharePopover().render();
        _this.update();
      }
    })(this));

    return this;
  },

  remove: function() {
    Backbone.View.prototype.remove.call(this); // super
    this.$el.remove();
    if (this.parent) {
      this.parent.refreshLayout();
    }
    this.stopListening();
    this.stop();
    return this;
  },

  hover: function(e) {
    if (e.type === 'mouseenter') {
      return $(e.currentTarget).find('.panel-background').addClass('hover');
    } else {
      return $(e.currentTarget).find('.panel-background').removeClass('hover');
    }
  },

  permissibleEvents: function() {
    var e = this.model.events;
    if (!!this._xhr) {
      e.push('stop_upload');  // add custom event not represented by model
    }
    return e;
  },

  onUploadProgress: function(data) {
    console.log(data.percent);
    console.log(data.message);

    if (!this.$('.progress .progress-bar').hasClass('progress-bar-info')) {
      this.$('.progress .progress-bar').removeClass('progress-bar-success').addClass('progress-bar-info');
    }
    this.$('.progress').addClass('active');
    this.$('.progress .progress-bar').css('width', '' + data.percent + '%');

    this.$('.message').html(data.message);
    if (data.percent === 100) {
      return this._xhr = null;
    } else if (!this._xhr) {
      return this._xhr = data.xhr;
    }
  },

  ping: function() {
    this.stop();
    this.interval = setInterval((function(_this) {
      return function() {
        console.log("=> poll (" + (_this.pollCount || 0) + ")");
        return _this.poll();
      };
    })(this), 2500 + parseInt(Math.random() * 1000));
  },

  stop: function() {
    return window.clearInterval(this.interval);
  },

  poll: function() {
    this.model.sync('read', this.model, {
      success: (function(_this) {
        return function(data) {
          if ((_this.model.attributes.progress || 0) === data.upload.progress) {
            _this.pollCount = (_this.pollCount || 0) + 1;
          } else {
            _this.pollCount = 0;
          }

          _this.model.set("progress", data.upload.progress);
          _this.model.set("status", data.upload.status);
          _this.update();

          if (!(_this.model.hasProgress() && (_this.pollCount || 0) < 50)) {
            _this.stop();
            _this.update();
          }
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          console.log("error fetching upload");
          _this.update(false);
        };
      })(this)
    });
  },

  update: function() {
    this.updateStatus();
    this.updateShare();
    this.updateProgress();
    this.updatePrivacy();
    this.updateSlugs();
  },

  updateSlugs: function() {
    this.$('a.edit-slug').attr('href', this.model.editURL());
    this.$('a.preview-slug').attr('href', this.model.previewURL());
    if (!!this.model.publishedURL()) {
      this.$('a.published-slug').attr('href', this.model.publishedURL());
    }
  },

  updatePrivacy: function() {
    var privacyEl = this.$('.btn-privacy');

    if (this.model.hasFinished()) {
      privacyEl
        .removeClass('private')
        .removeClass('public')
        .removeClass('unlisted');

      if (this.model.attributes.privacy === "unlisted") {
        privacyEl.addClass('unlisted');
      } else if (this.model.attributes.privacy === "public") {
        privacyEl.addClass('public');
      } else {
        privacyEl.addClass('private');
      }
      privacyEl.show();
    } else {
      privacyEl.hide();
    }
  },

  updateStatus: function() {
    this.$('.upload-status').html(this.model.statusMessage());
    this.$('.upload-status')
      .removeClass("running")
      .removeClass("error")
      .removeClass("success");

    if (this.model.hasFinished()) {
      this.$('.upload-status').addClass("success");
    } else if (this.model.hasStopped()) {
      this.$('.upload-status').addClass("danger");
    } else {
      this.$('.upload-status').addClass("warning");
    }
  },

  updateProgress: function() {
    var hasProgress = hasProgress || this.hasProgress();
    var progressBarEl = this.$('.progress .progress-bar');
      progressEl = this.$('.progress');

    progressBarEl.css('width', "" + this.model.attributes.progress + "%");

    progressBarEl
      .removeClass('progress-bar-info')
      .removeClass('progress-bar-success')
      .removeClass('progress-bar-warning')
      .removeClass('progress-bar-danger');

    // colors
    if (this.model.hasFinished()) {
      progressBarEl.addClass('progress-bar-success');
    } else if (this.model.hasStopped()) {
      progressBarEl.addClass('progress-bar-danger');
    } else {
      progressBarEl.addClass('progress-bar-warning');
    }

    // percentage progress
    // console.log("progress (" + this.model.attributes.progress + "%)");
    if (hasProgress) {
      progressEl.addClass('active').addClass('progress-striped');
    } else {
      progressEl.removeClass('active').removeClass('progress-striped');
    }
  },

  updateShare: function() {
    // share button
    if (this.model.canShareLink()) {
      this.$('.btn-share').show();
    } else {
      this.$('.btn-share').hide();
    }
  },

  trigger: function(view, event) {
    console.log(view, event);
  },

  initSharePopover: function() {
    return this.sharePopoverView = new App.Views.PopoversShare({
      parent: this,
      holder: this.$el.find('.btn-share'),
      placement: 'auto top'
    });
  },

  initPublishPopover: function() {
    return this.publishPopoverView = new App.Views.PopoversPublish({
      parent: this,
      holder: this.$el.find('.btn-privacy'),
      placement: "auto top",
      callbacks: {
        privacy: {
          success: this.updatePrivacy
        }
      }
    });
  },

  publishDocument: function() {
    NProgress.start();
    this.model.publish({ html: this.contentEditor.getHTML() }, {
      success: (function(_this) {
        return function(model) {
          NProgress.done();
          return window.location = window.location.origin + model.attributes.published_path;
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          NProgress.done();
          return $.notify("Error when saving document.", 'error');
        };
      })(this)
    });
  },

  hasProgress: function() {
    return this.hasUploadProgress() || this.model.hasProgress();
  },

  hasUploadProgress: function() {
    return !!this._xhr;
  }

});