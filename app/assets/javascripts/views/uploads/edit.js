App.Views.UploadsEdit = App.Views.UploadsBase.extend({
  template: JST['uploads/edit'],
  
  events: _.extend({
    'click .action-close' : 'replaceView',
  }, App.Views.UploadsBase.prototype.events),
  
  replaceView: function() {
    var edit = this;
    var show = new App.Views.UploadsShow({model: this.model});
    this.$el.replaceWith(show.render().el);
    edit.remove();
  }
});