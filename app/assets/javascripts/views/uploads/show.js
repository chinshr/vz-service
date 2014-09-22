App.Views.UploadsShow = App.Views.UploadsBase.extend({
  template: JST['uploads/show'],
  
  events: _.extend({
    'click #btn-preview' : 'preview',
    'click #btn-edit' : 'edit',
    'click #btn-open' : 'open'
  }, App.Views.UploadsBase.prototype.events),
  
  initialize: function() {
    _(function() {
      $('.btn-dropdown-toggle').dropdown();
    }).defer();
  },
  
  render: function() {
    // super
    App.Views.UploadsBase.prototype.render.call(this, {});
    return this;
  },
  
  preview: function() {
    alert('preview');
  },
  
  edit: function() {
    alert('edit document');
  },

  open: function() {
    alert('open document');
  }
});