App.Views.DocumentsContentEditorFormatPopover = App.Views.DocumentsBasePopover.extend({
  // template: JST['documents/content_editor_format_popover'],

  initialize: function(options) {
    App.Views.DocumentsBasePopover.prototype.initialize.call(this, options); // super
    _.bindAll(this, "setup", "teardown");
    this.shown = false;
  },

  render: function() {
    this.template = _.template($('#content-editor-format-template').html(), {});
    this.holder = $('#content-editor');
    this.popover = this.holder.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: 'top',
      template: '<div class="popover content-editor-format-popover" id="content-editor-format-popover"><div class="arrow"></div><div class="popover-content toolbar-nav"></div></div>',
      content: this.$el.html(this.template)
    }).on('show.bs.popover', function(e) {
      // console.log("show popover");
    }).on('shown.bs.popover', this.setup)
      .on('hidden.bs.popover', this.teardown)
      .on('inserted.bs.popover', function() { /* not firing! */ })
      .data("bs.popover");

    // TODO: event `inserted.bs.popover` does not work in this
    // version of Bootstrap, following is a workaround to set
    // position before the popover is inserted into DOM.
    $('body').on('DOMNodeInserted', (function(_this) {
      return function (e) {
        if ($(e.target).attr("id") === 'content-editor-format-popover') {
          pos = _this.callback(e.target);
          // $('#content-editor-format-popover').each(function () {
          _this.popover.$tip.each(function () {
            console.log(pos);
            this.style.setProperty('left', pos[0] + 'px', 'important');
            this.style.setProperty('top', pos[1] + 'px', 'important');
          });
        }
      }
    })(this));

    return this;
  },

  setup: function() {
    // console.log("shown popover");
    /* override = unset `!important` */
    // $('#content-editor-format-popover').each(function () {
    this.popover.$tip.each(function () {
      var style = this.style.cssText;
      style = style.replace(new RegExp('\\!important', 'g'), '');
      this.style.cssText = style;
    });

    /* re-bind toolbar */
    this.oid = 'format-' + this.generateObjectName();
    this.$el.attr('id', this.oid);
    this.parent.contentEditor.modules.toolbar.bind("#" + this.oid);
    this.shown = true;
  },

  teardown: function() {
    this.shown = false;
  },

  show: function(editor) {
    var sel = editor.root.ownerDocument.getSelection();
    if (sel && sel.rangeCount > 0) {
      var selrg = sel.getRangeAt(0);
      if (selrg) {
        var rects = selrg.getClientRects();
        if (rects.length > 0) {
          this.callback = (function(rect) {
            return function(popover) {
              var left = window.scrollX + rect.left + ((rect.right - rect.left) / 2) - ($(popover).width() / 2);
              var top  = window.scrollY + rect.top - $(popover).height() - 5;
              return [left, top];
            }
          })(rects[0]);

          var popover = $('#content-editor-format-popover');
          if (popover && popover.is(':visible')) {
            var pos = this.callback(popover);
            popover.stop().animate({
              left: pos[0],
              top: pos[1]
            }, 0);
          } else {
            // triggers event to position using callback
            $("#content-editor").popover("show");
          }
        }
      }
    }
  },

  hide: function() {
    if (this.shown) {
      this.holder.popover("hide");
    }
  },

  generateObjectName: function() {
    var text = "";
    var possible = "abcdefghijklmnopqrstuvwxyz0123456789";

    for (var i = 0; i < 10; i++) {
      text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
  }

});