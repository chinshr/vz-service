App.Views.UploadsBase = Backbone.View.extend({
  events: {
    'click .action-cancel' : 'onCancel',
    'click .action-delete': 'onDelete',
    'submit' : 'onFormSubmit',
    'keyup xinput': 'fieldChanged',
    'change select': 'selectionChanged',
    'mouseenter .show-panel': 'hover',
    'mouseleave .show-panel': 'hover'
  },
  
  render: function() {
    this.$el.html(this.template(this.model.attributes));
    return this;
  },
  
  initialize: function() {
    this.interval = null;
    this.listenTo(this.model, 'upload:progress', this.onUploadProgress);
    this.listenTo(this.model, 'destroy', this.remove);
    this.listenToOnce(this.model, 'sync', this.onSync);
  },
      
  hover: function(e) {
    if (e.type === 'mouseenter') {
      return $(e.currentTarget).find('.action-panel').addClass('hover');
    } else {
      return $(e.currentTarget).find('.action-panel').removeClass('hover');
    }
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

  onCancel: function(e) {
    if (this._xhr) {
      this._xhr.abort();
    }
    this.stop();
  },

  onDelete: function(e) {
    console.log("=> destroy");
    if (this._xhr) {
      this._xhr.abort();
    }
    this.model.destroy({
      wait: true,
      success: (function(_this) {
        return function(model, response) {
          _this.stop();
          _this.remove();
          console.log("=> destroyed");
        };
      })(this)
    });
  },

  onSync: function(event) {
    this.renderUpdate();
    // Note: after create (sync) ping-loop needs to be started.
    this.ping();  
  },
    
  onFormSubmit: function(e) {
    var data, form;
    e.originalEvent.preventDefault();
    form = $(e.target);
    data = {};
    _.map(form.serializeArray(), function(n) {
      var key;
      key = n['name'].match(/\[(.+)\]/);
      if (key.length > 1) {
        return data[key[1]] = n['value'];
      }
    });
    this.model.set(data);
    if (this.model.isValid(true)) {
      this.$(".btn").button("loading");
      return this.model.sync('update', this.model, {
        success: (function(_this) {
          return function() {
            return _this.$(".btn").button("reset");
          };
        })(this),
        error: (function(_this) {
          return function() {
            return _this.$(".btn").button("reset");
          };
        })(this)
      });
    }
  },
  
  ping: function() {
    this.interval = setInterval((function(_this) {
      return function() {
        console.log("=> poll");
        return _this.poll();
      };
    })(this), 2000 + parseInt(Math.random() * 500));
  },
      
  stop: function() {
    return window.clearInterval(this.interval);
  },
      
  poll: function() {
    this.model.sync('read', this.model, {
      success: (function(_this) {
        return function(data) {
          _this.model.set("progress", data.upload.progress);
          _this.model.set("status", data.upload.status);
          if (!_this.model.hasProgress()) {
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
      return this.$('.progress .progress-bar').addClass('progress-bar-success');
    }
  },
  
  fieldChanged: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data  = {};
    if (key = field.attr('name').match(/\[(.+)\]/)[1]) {
      data[key] = field.val();
      this.model.set(data);
      return this.model.validate();
    }
  },
            
  selectionChanged: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data = {};
    if (key = field.attr('name').match(/\[(.+)\]/)[1]) {
      data[key] = field.val();
      this.model.set(data);
      return this.model.validate();
    }
  },
  
  _hasProgress: function() {
    return this.model.hasProgress();
  },
});