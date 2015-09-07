App.Views.DocumentsBasePopover = Backbone.View.extend({

  initialize: function(options) {
    this.parent = options.parent;
    _.bindAll(this, "render", "show", "hide", "toggle", "destroy", "remove");
  },

  render: function() {
    return this;
  },

  show: function() {
    this.holder.popover("show");
  },

  hide: function() {
    this.holder.popover("hide");
  },

  toggle: function() {
    this.holder.popover("toggle");
  },

  destroy: function() {
    this.holder.popover("destroy");
    this.holder.remove();
    this.holder = null;
  },

  remove: function() {
    this.destroy();
  }
});
