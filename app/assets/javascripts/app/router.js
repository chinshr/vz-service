App.Router = Backbone.Router.extend({
  routes: {
    'dashboard' : 'dashboard',
    'd/:id/edit' : 'documentEdit',
    'd/:id' : 'documentShow',
    '@:user_id/:id' : 'documentPublish',
    '@:user_id' : 'profileShow',
    'explore' : 'explorer',
    'explore/tag/:id' : 'tagExplorer'
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
    var userId = $('#documents').data('user-id');
    var view = new App.Views.DocumentsIndex({query : {
      'sort_order': {'published_at': 'desc'},
      'user_id': userId,
      'any_of_status': [1]
    }});
  },

  explorer: function() {
    var view = new App.Views.DocumentsIndex({
      layout: 'grid-item col-lg-6 col-md-6 col-sm-6 col-xs-12',
      query : {
        'sort_order': {'published_at': 'desc'},
        'any_of_status': [1],
      }
    });
  },

  tagExplorer: function() {
    var tagName = $('#documents').data('tag-name'),
      tagSlug = $('#documents').data('tag-slug');

    var view = new App.Views.DocumentsIndex({
      layout: 'grid-item col-lg-6 col-md-6 col-sm-12 col-xs-12',
      query : {
        'sort_order': {'published_at': 'desc'},
        'any_of_status': [1],
        'any_of_tags': [tagName],
      }
    });
  }

});