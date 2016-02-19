App.Views.DocumentsBaseTile = {
  showTileClass: function() {
    return App.Views.DocumentsShowTile;
  },

  editTileClass: function() {
    return App.Views.DocumentsEditTile;
  },

  xupdate: function() {
    App.Views.TilesBase.prototype.update.call(this);
  }
};