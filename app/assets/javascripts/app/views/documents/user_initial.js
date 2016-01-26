App.Views.DocumentsUserInitial = Backbone.View.extend({
  template: JST['documents/user_initial'],
  tagName: 'option',

  initialize: function(options) {
    this.parent = options.parent;
  },

  render: function(params) {
    this.setElement(this.template(_.extend(this.model.attributes, params || {})));
    $('.gutter').append(this.$el);
    this.moveY(0).show();
    return this;
  },

  show: function() {
    // if (this.$el.length !== 0 && !this.$el.is(':visible')) {
    if (this.$el.length !== 0) {
      this.$el.animate({top: 0, opacity: 1}, 'fast');
    }
    return this;
  },

  hide: function() {
    // if (this.$el.length !== 0 && this.$el.is(':visible')) {
    if (this.$el.length !== 0) {
      this.$el.animate({top: 1, opacity: 0}, 'fast');
    }
    return this;
  },

  moveCursor: function(uuid, pos) {
    var manager = this.parent.contentEditorCursorManager;

    this.parent.contentEditorCursorManager.moveCursor(uuid, pos);

    if (manager.cursors[uuid]) {
      var caret = $(manager.cursors[uuid].elem).find(".cursor-caret");
      if (caret.length !== 0) {
        var gutter = $('.gutter')[0].getBoundingClientRect();
        var rect   = caret[0].getBoundingClientRect();
        this.moveY((rect.top + (rect.height / 2) - (this.height() / 2)) - gutter.top);
      }
    }
    return this;
  },

  moveY: function(top) {
    this.$el.stop().animate({
      top: top
    }, 0);
    return this;
  },

  moveX: function(left) {
    this.$el.animate({
      left: left
    }, 0);
    return this;
  },

  height: function() {
    return this.$el.height();
  },

  destroy: function() {
    this.hide();
    if (this.parent) {
      delete this.parent.users[this.model.attributes.username];
    }
    this.remove();
    this.unbind();
  }

});
