App.Views.PopoversShare = App.Views.PopoverBase.extend({
  template: JST['popovers/share'],

  initialize: function(options) {
    App.Views.PopoverBase.prototype.initialize.call(this, options); // super
    _.bindAll(this, "setup", "teardown");
  },

  render: function() {
    this.holder = this.holder || $('#share-button');
    this.popover = this.holder.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: this.placement,
      template: '<div class="popover share-popover" id="share-popover"><div class="arrow"></div><div class="popover-content"></div></div>',
      content: this.$el.html(this.template(_.extend({
        published_url: this.model.publishedURL(),
        preview_url: this.model.previewURL(),
        edit_url: this.model.editURL()
      }, this.model.attributes)))
    }).on('shown.bs.popover', this.setup)
      .on('hidden.bs.popover', this.teardown)
      .data("bs.popover");

    this.holder.on('click', (function(_this) {
      return function(e) {
        e.stopPropagation();
        _this.holder.tooltip('hide');
        /* close all other popovers except this */
        _this.holder.not(this).popover('hide');
        _this.popover.toggle();
      };
    })(this));

    $(document).on('click', (function(_this) {
      return function(e) {
        if (!$(e.target).is(_this.holder) && _this.holder.find($(e.target)).length === 0 && $('#share-popover').find($(e.target)).length === 0) {
          _this.hide();
        }
      }
    })(this));

    // close on escape
    $(document).keydown((function(_this) {
      return function(e) {
        e.stopPropagation();
        if (e.keyCode === 27) {
          _this.hide();
        }
      }
    })(this));

    return this;
  },

  setup: function() {
    this.holder.tooltip('disable');
    VZ.social.bind();
  },

  teardown: function() {
    VZ.social.unbind();
    this.holder.tooltip('enable');
  }
});