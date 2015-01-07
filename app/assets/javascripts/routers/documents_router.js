App.Routers.Documents = Backbone.Router.extend({
  routes: {
    '' : 'index',
    ':id/edit' : 'edit'
  },

  edit: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    view = new App.Views.DocumentsEdit({model: this.model});
    console.log('=> documents/edit/:' + id);
    return $('#document-container').html(view.render().el);
  }
});