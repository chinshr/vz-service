App.Views.TilesBase = Backbone.View.extend({
  events: {
    'mouseenter .show-panel': 'hover',
    'mouseleave .show-panel': 'hover'
  },

  initialize: function(options) {
    _.bindAll(this, "render", "remove", "hover", "trigger", "update", "updatePrivacy", "publishDocument", "documentId");
    this.parent = options.parent;
    this.listenTo(this.model, 'upload:progress', this.onUploadProgress);
    this.listenTo(this.model, 'destroy', this.remove);
    this.listenTo(this.model, 'change', this.update);
  },

  showTileClass: function() {
    return App.Views.TilesShow;
  },

  editTileClass: function() {
    return App.Views.TilesEdit;
  },

  render: function(attributes) {
    var template = this.template(_.extend(this.model.attributes, {
      // status_message: this.model.statusMessage(),
      events: this.permissibleEvents(),
      thumb_aspect_ratio_1_url: this.model.imageSource(1),
      thumb_bg_color: this.model.rgbaColor(),
      className: this.model.className
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
    // console.log(data.percent, data.status);
    this._xhr = data.xhr;
    this.model.set({
      progress: data.percent,
      state: data.status
    });
  },

  update: function() {
    this.updateShare();
    this.updateSlugs();
    this.updateProgress();
  },

  updateStatus: function() {
    var statusEl = this.$('.upload-status');

    if (typeof(this.model.attributes.state) !== 'undefined' ||
      typeof(this.model.attributes.status) !== 'undefined') {
      // statusEl.html(this.model.statusMessage());
      statusEl
        .removeClass("running")
        .removeClass("error")
        .removeClass("warning")
        .removeClass("success");

      if (this.model.hasFinished()) {
        statusEl.addClass("success");
      } else if (this.model.hasStopped()) {
        statusEl.addClass("danger");
      } else {
        statusEl.addClass("warning");
      }
      statusEl.html(this.model.humanizeState());
      statusEl.show();
    } else {
      statusEl.hide();
    }
  },

  updateProgress: function() {
    var percent = 0,
      progressEl = this.$('.progress'),
      progressBarEl = this.$('.progress .progress-bar');

    if (typeof(this.model.hasProgress) === 'function') {
      if (this.isFileUpload() && (!this.hasUploadProgress() || !!this.model.attributes.id)) {
        percent = 50;
      }
      if (this.isFileUpload() && (this.hasUploadProgress() || !!this.model.attributes.id)) {
        percent += (this.model.attributes.progress || 0) / 2;
      } else {
        percent = this.model.attributes.progress;
      }
      progressBarEl.css('width', "" + percent + "%");
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

      // to be 'striped' or not to be...
      if (this.hasProgress()) {
        progressEl.addClass('active').addClass('progress-striped');
      } else {
        progressEl.removeClass('active').removeClass('progress-striped');
      }
      progressEl.show();
    } else {
      progressEl.hide();
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

  updateSlugs: function() {
    this.$('a.edit-slug').attr('href', this.model.editURL());
    this.$('a.preview-slug').attr('href', this.model.previewURL());
    if (!!this.model.publishedURL()) {
      this.$('a.published-slug').attr('href', this.model.publishedURL());
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
          success: (function(_this) {
            return function() {
              _this.sharePopoverView.destroy(function() {
                _this.initSharePopover();
              });
            }
          })(this)
        },
        publish: {
          success: this.publishDocument
        }
      }
    });
  },

  publishDocument: function() {
    NProgress.start();
    this.model.publish({}, {
      success: (function(_this) {
        return function(model) {
          _.defer(function() {
            _this.publishPopoverView.hide();
            NProgress.done();
          });
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
  },

  isFileUpload: function() {
    return this.model.attributes && !!this.model.attributes.file_name;
  },

  documentId: function() {
    // override in subclass, returning the document_id for player
    return null;
  }
});
