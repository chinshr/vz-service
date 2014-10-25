App.Routers.Documents = Backbone.Router.extend({
  routes: {
    '' : 'index',
    ':id/edit' : 'edit'
  },

  initialize: function() {
  },

  edit: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    this.model.fetch();

    view = new App.Views.DocumentsEdit({model: this.model});
    return $('#uploads').html(view.render().el);

    console.log('=> documents/edit/:' + id);
  }
});