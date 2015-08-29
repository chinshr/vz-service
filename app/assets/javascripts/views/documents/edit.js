App.Views.DocumentsEdit = App.Views.DocumentsBase.extend({
  template: JST['documents/edit'],

  render: function() {
    this.$el.html(this.template(this.model.attributes));

    if (this.model.ok) {
      this.initSharePopover().render();
      this.initPublishPopover().render();
      this.initEditor();
      this.initPlayer();
      this.initUserInitials();
      this.initContentEditorFormatPopover();
      this.initTagEditor();
      $('#document-loading').hide();
      $('#document-edit').show();

      _.defer((function(_this) {
        return function() {
          // $('#publish-document').on('click', _.bind(this.publish, this));
          $('#publish-document').on('click', function() { alert("wow!"); });
        }
      })(this));

    } else if (this.model.errors) {
      $('#loading').hide();
      $('#document-load-error').show();
    }

    return this;
  },

  isEdit: function() { return true; }

});