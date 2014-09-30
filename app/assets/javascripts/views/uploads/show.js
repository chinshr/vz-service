App.Views.UploadsShow = App.Views.UploadsBase.extend({
  template: JST['uploads/show'],
  className: 'tile show-tile col-lg-4 col-md-4 col-sm-4',
  
  events: _.extend({
    'click .action-update' : 'flipTile',
    'click .action-edit' : 'onOpenEdit',
    'click .action-preview' : 'onOpenPreview',
    'click .action-delete': 'onDelete',
    'click .action-stop' : 'onStop',
    'click .action-stop' : 'onStart'
  }, App.Views.UploadsBase.prototype.events),
  
  initialize: function() {
    App.Views.UploadsBase.prototype.initialize.call(this); // super
  },

  render: function() {
    // super
    App.Views.UploadsBase.prototype.render.call(this, {});

    if (!this._hasUploadProgress()) {
      this.ping();
    }
    
    _.defer((function(_this) {
      return function() {
        $('.btn-dropdown-toggle').dropdown();
      }
    })(this));
    
    return this;
  },
  
  flipTile: function() {
    var show     = this;
    var showHTML = show.$el;
    var edit     = new App.Views.UploadsEdit({model: this.model});
    var editHTML = edit.render().$el;
    
    if (Modernizr.csstransforms3d) {
      editHTML.find('.panel').css({
        'transform': 'rotateY(180deg)',
        '-webkit-transform': 'rotateY(180deg)',
        'position': 'absolute',
        'top': '0',
        'left': '0',
        'width': '100%'
      }).appendTo(showHTML.find('.flipper'));

      showHTML.addClass('flip');
      showHTML.bind('transitionend -moz-transitionend -webkit-transitionend -o-transitionend', (function(_this) {
        return function(e) {
          _this.$el.replaceWith(edit.render(_this.model.attributes).el);
          show.remove();
          console.log("=> transition ended");
        };
      })(this));
    } else {
      this.$el.replaceWith(edit.render(this.model.attributes).el);
      show.remove();
    }
  },

  onOpenEdit: function() {
    alert('open edit document');
  },

  onOpenPreview: function() {
    alert('open preview document');
  },
  
  onStop: function(e) {
    if (this._xhr) {
      this._xhr.abort();
    } else {
      this.model.set({event: 'stop'});

      return this.model.sync('update', this.model, {
        success: (function(_this) {
          return function() {
            _this.stop();
            return _this.renderUpdate();
          };
        })(this),
        error: (function(_this) {
          console.log("upload could not be stopped.");
        })(this)
      });
    }
  },

  onStart: function(e) {
    this.model.set({event: 'start'});

    return this.model.sync('update', this.model, {
      success: (function(_this) {
        return function() {
          _this.stop();
          return _this.renderUpdate();
        };
      })(this),
      error: (function(_this) {
        console.log("upload could not be started.");
      })(this)
    });
  },

  onDelete: function(e) {
    console.log("=> destroy");
    $.confirm("Do you really want to delete '" + _.escape(this.model.attributes.title) + "'?", (function(_this) {
      return function(result) {
        if (!!result) {
          if (_this._xhr) {
            _this._xhr.abort();
          }
          _this.model.destroy({
            wait: true,
            success: (function(__this) {
              return function(model, response) {
                __this.stop();
                __this.remove();
                console.log("=> destroyed");
              };
            })(_this)
          });
        }
      }
    })(this));
  }
});