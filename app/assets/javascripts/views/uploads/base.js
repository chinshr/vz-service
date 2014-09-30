App.Views.UploadsBase = Backbone.View.extend({
  tagName: 'div',
  events: {
    'mouseenter .show-panel': 'hover',
    'mouseleave .show-panel': 'hover'
  },
  
  initialize: function() {
    this.interval = null;
    this.listenTo(this.model, 'upload:progress', this.onUploadProgress);
    this.listenTo(this.model, 'destroy', this.remove);
    this.listenToOnce(this.model, 'sync', this.onSync);
  },
      
  render: function(attributes) {
    this.$el.html(this.template(_.extend(this.model.attributes, {
      message: this.model.message(), 
      events: this.permissibleEvents()
    })));
    
    _.defer((function(_this) {
      return function() {
        _this.renderUpdate();
      }
    })(this));
    
    return this;
  },
  
  remove: function() {
    // overload remove
    this.$el.remove();
    this.stopListening();
    this.stop();
    return this;
  },
  
  hover: function(e) {
    if (e.type === 'mouseenter') {
      return $(e.currentTarget).find('.action-panel').addClass('hover');
    } else {
      return $(e.currentTarget).find('.action-panel').removeClass('hover');
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
    this.$('.progress .progress-bar').css('width', '' + data.percent + '%');
    this.$('.message').html(data.message);
    if (data.percent === 100) {
      return this._xhr = null;
    } else if (!this._xhr) {
      return this._xhr = data.xhr;
    }
  },

  onSync: function(event) {
    // this.renderUpdate();
    // Note: after create (sync) ping-loop needs to be started.
    this.ping();  
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
          if ((_this.model.progress || 0) === data.upload.progress) {
            _this.pollCount = (_this.pollCount || 0) + 1;
          } else {
            _this.pollCount = 0;
          }
          _this.model.set("progress", data.upload.progress);
          _this.model.set("status", data.upload.status);
          if (!(_this.model.hasProgress() && (_this.pollCount || 0) < 50)) {
            _this.stop();
            _this.renderUpdate();
          }
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          console.log("error fetching upload ID = " + _this.data.upload.id);
          _this.renderUpdate(false);
        };
      })(this)
    });
  },

  renderUpdate: function(hasProgress) {
    hasProgress = hasProgress || this._hasProgress();
    
    this.$('.message').html(this.model.message());
    this.$('.alert-slug-link').html("<a href=\"" + this.model.attributes.slug + "\" target=\"_blank\">http://voyz.es/" + this.model.attributes.slug + "</a>");
    this.$('.alert-slug').show();
    this.$('.progress .progress-bar').css('width', "" + this.model.attributes.progress + "%");
    if (hasProgress) {
      this.$('.progress').addClass('active');
    } else {
      this.$('.progress').removeClass('active');
    }
    
    if (this.model.hasFinished()) {
      this.$('.status').removeClass('label-info').addClass('label-success');
    } else if (this.model.hasStopped()) {
      this.$('.status').removeClass('label-info').removeClass('label-success').removeClass('label-warning').addClass('label-danger');
    }
    
    if (!this.$('.progress .progress-bar').hasClass('progress-bar-success')) {
      this.$('.progress .progress-bar').removeClass('progress-bar-info');
      this.$('.progress .progress-bar').addClass('progress-bar-success');
    }
    
    // dropdown
    if (this._hasProgress()) {
      this.$('.action-stop').parent().removeClass('disabled');
    } else {
      this.$('.action-stop').parent().addClass('disabled');
    }

    if (_.contains(this.model.events, 'start')) {
      this.$('.action-start').parent().removeClass('disabled');
    } else {
      this.$('.action-start').parent().addClass('disabled');
    }
    
    // privacy
    if (this.model.attributes.privacy === "private") {
      this.$('.icon-privacy').
        addClass('icon-private').addClass('glyphicon-lock').
        removeClass('icon-public').removeClass('glyphicon-book');
    } else {
      this.$('.icon-privacy').
        removeClass('icon-private').removeClass('glyphicon-lock').
        addClass('icon-public').addClass('glyphicon-book');
    }
  },
  
  _hasProgress: function() {
    return this._hasUploadProgress() || this.model.hasProgress();
  },
  
  _hasUploadProgress: function() {
    return !!this._xhr;
  }
});