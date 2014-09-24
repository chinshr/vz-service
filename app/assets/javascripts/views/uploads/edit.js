App.Views.UploadsEdit = App.Views.UploadsBase.extend({
  template: JST['uploads/edit'],
  
  events: _.extend({
    'click .action-close' : 'replaceView',
  }, App.Views.UploadsBase.prototype.events),
  
  initialize: function() {
    this.tags = ["red", "green", "blue"];
    _.defer((function(_this) {
      return function() {
        $('.input-taggable').select2({
          tags: function() { return _this.tags},
          maximumInputLength: 15,
          tokenSeparators: [",", " "]
        });
      }
    })(this));
  },
  
  replaceView: function() {
    var edit = this;
    var show = new App.Views.UploadsShow({model: this.model});
    this.$el.replaceWith(show.render().el);
    edit.remove();
  }
});