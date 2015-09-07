App.Views.DocumentsContentViewerSelectionPopover = App.Views.DocumentsBasePopover.extend({

  initialize: function(options) {
    App.Views.DocumentsBasePopover.prototype.initialize.call(this, options); // super
    _.bindAll(this, "setup", "teardown", "reposition");
    this.shown = false;
    this.oid = this.generateObjectId();
    this.tid = null;
    this.pid = null;
  },

  render: function() {
    this.template = _.template($('#content-editor-toolbar-template').html(), {});
    this.holder = $('#content-viewer');
    this.popover = this.holder.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: 'top',
      template: '<div class="popover content-viewer-selection-popover popover-ace" id="content-viewer-selection-popover"><div class="arrow"></div><div class="popover-content toolbar-nav"></div></div>',
      content: this.$el.html(this.template)
    }).on('show.bs.popover', (function(_this) {
      return function(e) {
        //_this.reposition(_this.popover.$tip);
      }
    })(this)).on('shown.bs.popover', this.setup)
      .on('hidden.bs.popover', this.teardown)
      .on('inserted.bs.popover', function() { /* not firing! */ })
      .data("bs.popover");

    // TODO: event `inserted.bs.popover` does not work in this
    // version of Bootstrap, following is a workaround to set
    // position before the popover is inserted into DOM.
    $('body').on('DOMNodeInserted', (function(_this) {
      return function (e) {
        if ($(e.target).attr("id") === 'content-viewer-selection-popover') {
          _this.reposition(e.target);
        }
      }
    })(this));

    return this;
  },

  setup: function() {
    /* re-bind toolbar */
    this.tid = 'content-viewer-selection-toolbar-' + this.oid;
    this.$el.attr('id', this.tid);
    this.shown = true;
  },

  teardown: function() {
    this.shown = false;
    $("#" + this.pid).remove();
  },

  show: function(sel) {
    sel = sel || this.parent.getSelection();
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

          if (this.shown) {
            this.reposition(this.popover.$tip);
          } else {
            this.holder.popover('show');
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

  reposition: function(target) {
    var pos = this.callback(target);

    if (this.shown) {
      $("#" + this.pid).remove();
      $(target).stop().animate({
        left: pos[0],
        top: pos[1]
      }, 0);
      // console.log('reposition(true)', pos);
    } else {
      this.pid = 'content-viewer-popover-position-css-' + this.oid;

      $("<style>")
      .prop("type", "text/css")
      .prop("id", this.pid)
      .html("\
        .popover-ace {\
          left: " + pos[0] + "px !important;\
          top: " + pos[1] + "px !important;\
        }\
      ")
      .appendTo("head");
      // console.log('reposition(false)', pos);
    }
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