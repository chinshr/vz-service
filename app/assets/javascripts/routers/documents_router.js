App.Routers.Documents = Backbone.Router.extend({
  routes: {
    '' : 'index',
    ':id/edit' : 'edit',
    ':id' : 'show'
  },

  edit: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    view = new App.Views.DocumentsEdit({model: this.model});
    console.log('=> documents/:' + id + "/edit");
    return $('#document-container').html(view.render().el);
  },

  show: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    view = new App.Views.DocumentsShow({model: this.model});
    console.log('=> documents/:' + id);
    return $('#document-container').html(view.render().el);
  }

});