App.Views.UploadsShowTile = App.Views.TilesShow.extend(_.extend(Backbone.View, App.Views.UploadsBaseTile, {

  render: function() {
    var _this = this;
    App.Views.TilesShow.prototype.render.call(this, {}); // super
    //_.defer(function() {
      _this.initMorePopover().render();
    //});
    return this;
  },

  update: function() {
    App.Views.TilesShow.prototype.update.call(this); // super
    this.updateStatus();
    this.updateProgress();
    this.updatePrivacy();
    this.morePopoverView.update();
  },

}));
