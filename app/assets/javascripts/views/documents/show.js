App.Views.DocumentsShow = App.Views.DocumentsBase.extend({

  render: function() {
    if (this.model.ok) {
      this.initPlayer();
    }
    return this;
  }

});