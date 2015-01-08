App.Views.DocumentsEdit = App.Views.DocumentsBase.extend({
  template: JST['documents/edit'],

  render: function() {
    this.$el.html(this.template(this.model.attributes));
    if (this.model.ok) {
      this.initEditor();
      this.initPlayer();
      $('#document-loading').hide();
      $('#document-edit').show();
    } else if (this.model.errors) {
      $('#loading').hide();
      $('#document-load-error').show();
    }
    return this;
  },

});