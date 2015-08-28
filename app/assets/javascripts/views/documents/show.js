App.Views.DocumentsShow = App.Views.DocumentsBase.extend({
  template: JST['documents/show'],

  initialize: function() {
    App.Views.DocumentsBase.prototype.initialize.call(this); // super
    $(document).on('mouseup', _.bind(this.selectionHandler, this));
  },

  render: function() {
    this.$el.html(this.template(this.model.attributes));

    if (this.model.ok) {
      this.initSharePopover().render();
      this.initPublishPopover().render();
      this.initEditor();
      this.initPlayer();
      // this.initContentViewerSelectionPopover();

      $('#document-loading').hide();
      $('#document-show').show();
    } else {
      $('#loading').hide();
      $('#document-load-error').show();
    }

    return this;
  },

  initContentViewerSelectionPopover: function() {
    $('#content-viewer').popover({
      container: 'body',
      html: true,
      trigger: 'manual',
      placement: 'top',
      template: '<div class="popover content-viewer-selection-popover" id="content-viewer-selection-popover"><div class="arrow"></div><div class="popover-content toolbar-nav"></div></div>',
      content: function() {
        var ob = $('nav ul.content-viewer-toolbar-container');
        var nb = ob.clone();
        nb.attr('id', 'foo');
        return nb.wrap('<div>').parent().html();
      }
    }).on('show.bs.popover', function(e) {
      // console.log("show popover");
    }).on('shown.bs.popover', _.bind(function(e) {
      // console.log("shown popover");
      /* override = unset `!important` */
      $('#content-viewer-selection-popover').each(function () {
        var style = this.style.cssText;
        style = style.replace(new RegExp('\\!important', 'g'), '');
        this.style.cssText = style;
      });
      /* re-bind share events */
      // this.contentEditor.modules.toolbar.bind("#foo");
    }, this));

    // TODO: event `inserted.bs.popover` does not work in this
    // version of Bootstrap, following is a workaround to set
    // position before the popover is inserted into DOM.
    $('body').on('DOMNodeInserted', (function(_this) {
      return function (e) {
        if ($(e.target).attr("id") === 'content-viewer-selection-popover') {
          pos = _this.callback(e.target);
          $('#content-viewer-selection-popover').each(function () {
            this.style.setProperty('left', pos[0] + 'px', 'important');
            this.style.setProperty('top', pos[1] + 'px', 'important');
          });
        }
      }
    })(this));
  },

  selectionHandler: function() {
    var sel = this.getSelection();
    if (sel.rangeCount > 0) {
      var range = sel.getRangeAt(0);
      if (range.startOffset && range.endOffset && range.endOffset > range.startOffset) {
        this.showContentViewerSelectionPopover(sel);
      } else {
        this.hideContentViewerSelectionPopover();
      }
    } else {
      this.hideContentViewerSelectionPopover();
    }
  },

  showContentViewerSelectionPopover: function(sel) {
    sel = sel || this.getSelection();
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
            $("#content-viewer").popover("show");
          }
        }
      }
    }
  },

  hideContentViewerSelectionPopover: function() {
    var popover = $('#content-viewer-selection-popover');
    if (popover && popover.is(':visible')) {
      $("#content-viewer").popover("hide");
    }
  },

  getSelection: function() {
    if (window.getSelection) {
      return window.getSelection();
    } else if (document.selection && document.selection.type != "Control") {
      return document.selection;
    }
  },

  isShow: function() { return true; }

});