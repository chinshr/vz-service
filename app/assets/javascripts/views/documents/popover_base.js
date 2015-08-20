App.Views.DocumentsPopoverBase = Backbone.View.extend({

  initialize: function(options) {
    this.parent = options.parent;
    _.bindAll(this, "render", "show", "hide", "toggle", "destroy", "remove");
  },

  render: function() {
    return this;
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
