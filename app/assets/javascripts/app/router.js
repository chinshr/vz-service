App.Router = Backbone.Router.extend({
  routes: {
    'dashboard' : 'dashboard',
    'd/:id/edit' : 'documentEdit',
    'd/:id' : 'documentShow',
    '@:user_id/:id' : 'documentPublish',
    '@:user_id' : 'profileShow'
  },

  initialize: function() {
  },

  dashboard: function() {
    var view = new App.Views.UploadsIndex();
  },

  documentEdit: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    view = new App.Views.DocumentsEdit({model: this.model});
    return $('#document-container').html(view.render().el);
  },

  documentShow: function(id) {
    var view;
    this.model = new App.Models.Document({id: id});
    view = new App.Views.DocumentsShow({model: this.model});
    return $('#document-container').html(view.render().el);
  },

  documentPublish: function(user_id, id) {
    var view;
    this.model = new App.Models.Document({id: id, user_id: user_id});
    view = new App.Views.DocumentsPublish({model: this.model});
    return $('#document-container').html(view.render().el);
  },

  profileShow: function(user_id) {
    var view = new App.Views.DocumentsIndex();
  }

});