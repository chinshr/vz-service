App.Routers.Documents = Backbone.Router.extend({
  routes: {
    '' : 'index',
    ':id/edit' : 'edit'
  },

  index: function() {
    alert('documents index');
  },

  edit: function(id) {
    alert('documents edit ' + id);
  }
});