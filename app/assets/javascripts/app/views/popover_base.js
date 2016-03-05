App.Views.PopoverBase = Backbone.View.extend({

  initialize: function(options) {
    _.bindAll(this, "render", "show", "hide", "toggle", "destroy", "remove");
    this.parent    = options.parent;
    this.model     = options.model || this.parent.model;
    this.holder    = options.holder;
    this.placement = options.placement || 'auto bottom';
  },

  render: function() {
    return this;
  },

  show: function() {
    this.holder.popover("show");
    return this;
  },

  hide: function() {
    this.holder.popover("hide");
    return this;
  },

  toggle: function() {
    this.holder.popover("toggle");
    return this;
  },

  destroy: function(callback) {
    //this.holder.popover("disable");

    this.undelegateEvents();
    this.$el.removeData().unbind();
    Backbone.View.prototype.remove.call(this);

    if (callback) {
      callback(this);
    }
    delete this;
    return this;
  },

  remove: function() {
    this.destroy();
    return this;
  },

  generateObjectId: function() {
    var text = "";
    var possible = "abcdefghijklmnopqrstuvwxyz0123456789";
    for (var i = 0; i < 5; i++) {
      text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
  }

});
