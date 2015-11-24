App.Views.DocumentsSharePopover = App.Views.DocumentsBasePopover.extend({
  template: JST['documents/share_popover'],

  initialize: function(options) {
    App.Views.DocumentsBasePopover.prototype.initialize.call(this, options); // super
    _.bindAll(this, "setup", "teardown");
  },

  render: function() {
    this.holder = $('#share-button');
    this.popover = this.holder.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: 'bottom',
      template: '<div class="popover share-popover" id="share-popover"><div class="arrow"></div><div class="popover-content"></div></div>',
      content: this.$el.html(this.template(_.extend({
        published_url: document.location.origin + this.model.attributes.published_path
      }, this.model.attributes)))
    }).on('shown.bs.popover', this.setup)
      .on('hidden.bs.popover', this.teardown)
      .data("bs.popover");

    this.holder.on('click', (function(_this) {
      return function(e) {
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