App.Views.TilesShow = App.Views.TilesBase.extend({
  template: JST['tiles/show'],

  events: _.extend({
    'click .action-update': 'flipTile',
    'click .add-tags-link': 'flipTile',
    'click .action-edit': 'onOpenEdit',
    'click .action-preview': 'onOpenPreview',
    'click .action-delete': 'onDelete',
    'click .action-stop': 'onStop',
    'click .action-start': 'onStart',
    'click .action-reset': 'onReset',
    'click .show-more-tags-link': 'showMoreTags'
  }, App.Views.TilesBase.prototype.events),

  initialize: function(options) {
    _.bindAll(this, "flipTile", "playerOptions", "initPlayerButton",
      "playerLoading", "playerReady", "playerDestroy",
      "playerError", "playerPlay", "playerPause", "playerStop", "playerFinish",
      "onStart", "onStop", "onReset", "syncEvent", "showMoreTags", "shortenDescription");
    App.Views.TilesBase.prototype.initialize.call(this, options); // super
  },

  render: function(attributes) {
    App.Views.TilesBase.prototype.render.call(this, attributes); // super

    _.defer((function(_this) {
      return function() {
        _this.initPlayerButton();
        _this.shortenDescription();
      }
    })(this));

    return this;
  },

  update: function() {
    App.Views.TilesBase.prototype.update.call(this); // super
    if (this.model.hasFinished()) {
      if (!this.$(".thumb-play-pause").hasClass("play") || !this.$(".thumb-play-pause").hasClass("pause")) {
        this.$(".thumb-play-pause").addClass("play");
      }
    }
  },

  playerOptions: function(options) {
    return _.extend({
      document_id: this.documentId(),
      holder: this,
      callbacks: {
        loading: this.playerLoading,
        ready: this.playerReady,
        destroy: this.playerDestroy,
        error: this.playerError,
        play: this.playerPlay,
        pause: this.playerPause,
        stop: this.playerStop,
        finish: this.playerFinish
      }
    }, options);
  },

  initPlayerButton: function() {
    var _this = this,
      options = this.playerOptions();

    this.$(".thumb-play-pause").on('click', function(e) {
      e.stopPropagation();
      e.preventDefault();

      if (!_this.model.hasFinished()) {
        return;
      }

      if (_this.parent && !_this.parent.player) {
        _this.parent.initPlayer(options);
      } else if (_this.parent && _this.parent.player && _this.parent.player.document_id !== _this.documentId()) {
        _this.parent.player.destroy();
        _this.parent.initPlayer(options);
      } else if (_this.parent && _this.parent.player && _this.parent.player.document_id === _this.documentId() && _this.parent.player.isReady()) {
        _this.parent.player.togglePlay();
      }
    });
  },

  playerLoading: function() {
    var playPauseEl = this.$(".thumb-play-pause");
    this.$(".loading").addClass("spinner");
    playPauseEl.addClass("sticky");
  },

  playerReady: function(player) {
    this.$(".loading").removeClass("spinner");
    if (player.model && player.model.attributes.html) {
      this.$(".animated-segments-content").html(player.model.attributes.html);
      this.$(".animated-segments-content").addClass("start").addClass("pause");
    }
    this.parent.player.play();
  },

  playerDestroy: function() {
    var playPauseEl = this.$(".thumb-play-pause");
    playPauseEl.removeClass("sticky");
    this.$(".loading").removeClass("spinner");
  },

  playerError: function() {
    console.log("Player error");
  },

  playerPlay: function() {
    var playPauseEl = this.$(".thumb-play-pause");
    playPauseEl.addClass("pause").addClass("sticky").removeClass("play");
    this.$(".animated-segments-content").addClass("play").removeClass("pause");
  },

  playerPause: function() {
    var playPauseEl = this.$(".thumb-play-pause");
    playPauseEl.addClass("play").addClass("sticky").removeClass("pause");
    this.$(".animated-segments-content").addClass("pause").removeClass("play");
  },

  playerStop: function() {
    var playPauseEl = this.$(".thumb-play-pause");
    playPauseEl.addClass("play").removeClass("pause");
  },

  playerFinish: function() {
    this.parent.player.stop();
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
      // edit       = new App.Views.TilesEdit({model: this.model}).render(),
      edit       = new (this.editTileClass())({model: this.model, parent: this.parent}).render(),
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
        if (edit.parent) {
          edit.parent.refreshLayout();
        }
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

  onStop: function(e) {
    var _this = this;
    if (this._xhr) {
      this._xhr.abort();
    } else {
      this.syncEvent('fail');
    }
  },

  onStart: function(e) {
    this.syncEvent('start');
  },

  onReset: function(e) {
    this.syncEvent('reset');
  },

  syncEvent: function(event) {
    var _this = this;
    this.model.set({event: event});
    return this.model.sync('update', this.model, {
      success: function() {
        _this.stop();
        return _this.update();
      },
      error: function() {
        $.alert("Could not '" + event + "'.");
      }
    });
  },

  onDelete: function(e) {
    $.confirm("Do you really want to remove \"" + _.escape(this.model.attributes.title) + "\"?", (function(_this) {
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

  initMorePopover: function() {
    return this.morePopoverView = new App.Views.UploadsMorePopover({
      parent: this,
      placement: "auto top"
    });
  },

  initStatusPopover: function() {
    return this.statusPopoverView = new App.Views.UploadsStatusPopover({
      parent: this,
      placement: "auto bottom"
    });
  },

  showMoreTags: function(e) {
    e.stopPropagation();
    e.preventDefault();
    $(e.target).parent().hide();
    $(e.target).closest('ul').find('.show-less').removeClass('show-less');
    this.parent.refreshLayout();
  },

  shortenDescription: function() {
    var _this = this,
      elements = this.$('p.minimize'),
      shortLength = 50;

    elements.each(function(){
      var t = $(this).text();
      if(t.length < shortLength) return;

      $(this).html(
        t.slice(0, shortLength) + '<span> </span><a href="#" class="more-link">...more</a>' +
        '<span style="display:none;">' + t.slice(shortLength, t.length)
      );
    });

    $('.more-link', elements).click(function(event) {
      event.preventDefault();
      $(this).hide().prev().hide();
      $(this).next().show();
      _this.parent.refreshLayout();
    });
  }

});
