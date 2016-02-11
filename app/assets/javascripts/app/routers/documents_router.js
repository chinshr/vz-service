App.Routers.Documents = Backbone.Router.extend({
  routes: {
    '' : 'index',
    'd/:id/edit' : 'edit',
    'd/:id' : 'show',
    '@:user_id/:id' : 'publish'
  },

  edit: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    view = new App.Views.DocumentsEdit({model: this.model});
    return $('#document-container').html(view.render().el);
  },

  show: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    view = new App.Views.DocumentsShow({model: this.model});
    return $('#document-container').html(view.render().el);
  },

  publish: function(user_id, id) {
    var view;
    this.model = new App.Models.Document({id: id, user_id: user_id});
    view = new App.Views.DocumentsPublish({model: this.model});
    return $('#document-container').html(view.render().el);
  }

});