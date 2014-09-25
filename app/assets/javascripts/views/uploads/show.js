App.Views.UploadsShow = App.Views.UploadsBase.extend({
  template: JST['uploads/show'],
  
  events: _.extend({
    'click .action-update' : 'replaceView',
    'click .action-edit' : 'openEdit',
    'click .action-preview' : 'openPreview',
    'click .action-delete' : 'doDelete'
  }, App.Views.UploadsBase.prototype.events),
  
  initialize: function() {
    _.defer((function(_this) {
      return function() {
        $('.btn-dropdown-toggle').dropdown();
        _this.ping();
      }
    })(this));
  },
  
  render: function() {
    // super
    App.Views.UploadsBase.prototype.render.call(this, {});
    return this;
  },
  
  replaceView: function() {
    var show = this;
    var edit = new App.Views.UploadsEdit({model: this.model});
    this.$el.replaceWith(edit.render().el);
    show.remove();
  },

  openEdit: function() {
    alert('open edit document');
  },

  openPreview: function() {
    alert('open preview document');
  },

  doDelete: function() {
    alert('delete');
  }
  
});