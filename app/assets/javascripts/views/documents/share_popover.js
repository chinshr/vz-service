App.Views.DocumentsSharePopover = Backbone.View.extend({
  template: JST['documents/share_popover'],

  initialize: function(options) {
    this.parent = options.parent;
    _.bindAll(this, "render", "show", "hide", "toggle", "destroy", 
      "remove", "setup", "teardown");
  },

  render: function() {
    this.button = $('#share-button');
    this.popover = this.button.popover({
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

    this.button.on('click', (function(_this) {
      return function(e) {
        $('#share-button').tooltip('hide');
        /* close all other popovers except this */
        $('#share-button').not(this).popover('hide');
        _this.popover.toggle();
      };
    })(this));

    $(document).on('click', (function(_this) {
      return function(e) {
        if (!$(e.target).is(_this.button) && $('#share-popover').find($(e.target)).length === 0) {
          _this.hide();
        }
      }
    })(this));

    return this;
  },

  setup: function() {
    VZ.social.bind();
  },

  teardown: function() {
    VZ.social.unbind();
  },

  show: function() {
    this.button.popover("show");
  },

  hide: function() {
    this.button.popover("hide");
  },

  toggle: function() {
    this.button.popover("toggle");
  },

  destroy: function() {
    this.button.popover("destroy");
    this.button.remove();
    this.button = null;
  },

  remove: function() {
    this.destroy();
  }
});