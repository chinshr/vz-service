App.Views.DocumentsPublish = App.Views.DocumentsBase.extend({

  initialize: function() {
    App.Views.DocumentsBase.prototype.initialize.call(this); // super
    $(document).on('mouseup', _.bind(this.selectionHandler, this));
  },

  render: function() {
    if (this.model.ok) {
      this.initSharePopover().render();
      this.initPlayer();
      this.initContentViewerSelectionPopover().render();
    }
    return this;
  },

  initContentViewerSelectionPopover: function() {
    return this.contentViewerSelectionPopoverView = new App.Views.DocumentsContentViewerSelectionPopover({
      model: this.model,
      parent: this
    });
  },

  selectionHandler: function() {
    var sel = this.getSelection();
    if (sel.rangeCount > 0) {
      var range = sel.getRangeAt(0);
      // console.log(range);
      if (typeof(range.startOffset) === 'number' && typeof(range.endOffset) === 'number' && Math.abs(range.endOffset - range.startOffset) > 0) {
        // this.showContentViewerSelectionPopover(sel);
        this.contentViewerSelectionPopoverView.show(sel);
      } else {
        // this.hideContentViewerSelectionPopover();
        this.contentViewerSelectionPopoverView.hide();
      }
    } else {
      // this.hideContentViewerSelectionPopover();
      this.contentViewerSelectionPopoverView.hide();
    }
  },

  getSelection: function() {
    if (window.getSelection) {
      return window.getSelection();
    } else if (document.getSelection) {
      return document.getSelection();
    } else if (document.selection) {
      return document.selection.createRange();
    }
  },

  isPublish: function() { return true; }
});