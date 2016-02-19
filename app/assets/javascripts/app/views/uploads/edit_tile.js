App.Views.UploadsEditTile = App.Views.TilesEdit.extend(_.extend(Backbone.View, App.Views.UploadsBaseTile, {

  update: function() {
    App.Views.TilesEdit.prototype.update.call(this); // super
    this.updateStatus();
    this.updateProgress();
    this.updatePrivacy();
  },

}));
