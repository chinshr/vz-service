App.Views.UploadsShow = App.Views.UploadsBase.extend({
  template: JST['uploads/show'],
  className: 'tile show-tile col-lg-4 col-md-4 col-sm-4',

  events: _.extend({
    'click .action-update' : 'flipTile',
    // 'dblclick .action-more' : 'flipTile',
    'click .action-edit' : 'onOpenEdit',
    'click .action-preview' : 'onOpenPreview',
    'click .action-delete': 'onDelete',
    'click .action-stop' : 'onStop',
    'click .action-start' : 'onStart'
  }, App.Views.UploadsBase.prototype.events),

  initialize: function(options) {
    _.bindAll(this, "flipTile");
    App.Views.UploadsBase.prototype.initialize.call(this, options); // super
  },

  render: function() {
    App.Views.UploadsBase.prototype.render.call(this, {}); // super
    this.initMorePopover().render();
    return this;
  },

  trigger: function(view, event) {
    var target = $(event.target),
      _this = this,
      typeSelector, method;

    for (var k in this.events) {
      typeSelector = k.split(' ');
      if (target.is(typeSelector[1])) {
        method = this.events[k];
        if (_.contains(_.functions(this), method)) {
          this[method](event);
        }
      }
    }
  },

  flipTile: function(event) {
    var show     = this,
      showHTML   = show.$el,
      edit       = new App.Views.UploadsEdit({model: this.model}).render(),
      editHTML   = edit.template(edit.model.attributes);

    if (event) {
      event.stopPropagation();
      event.originalEvent.preventDefault();
    }
    if (Modernizr.csstransforms3d) {
      $(editHTML).find('.panel').css({
        'transform': 'rotateY(180deg)',
        '-webkit-transform': 'rotateY(180deg)',
        'position': 'absolute',
        'top': '0',
        'left': '0',
        'width': '100%'
      }).appendTo(showHTML.find('.flipper'));
      showHTML.bind('transitionend -moz-transitionend -webkit-transitionend -o-transitionend', function(e) {
        show.$el.parent().append(edit.$el);
        show.remove();
      });
      showHTML.addClass('flip');
    } else {
      show.$el.parent().append(edit.$el);
      show.remove();
    }
  },

  onOpenEdit: function() {
    window.location = '/d/' + this.model.attributes.slug_id + '/edit';
  },

  onOpenPreview: function() {
    window.location = '/d/' + this.model.attributes.slug_id;
  },

  onOpenPublished: function() {
    console.log("-->> go to published document");
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
            return _this.update();
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
          return _this.update();
        };
      })(this),
      error: (function(_this) {
        console.log("upload could not be started.");
      })(this)
    });
  },

  onReset: function(e) {
    console.log("-->> onReset ");
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
  },

  update: function() {
    App.Views.UploadsBase.prototype.update.call(this); // super
    this.morePopoverView.update();
  },

  initMorePopover: function() {
    return this.morePopoverView = new App.Views.UploadsMorePopover({
      parent: this,
      placement: "auto top"
    });
  }

});