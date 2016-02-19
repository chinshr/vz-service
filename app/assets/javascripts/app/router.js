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
    var _this           = this,
      collection        = new App.Collections.AccountUploads(),
      collectionFetched = new $.Deferred;

    collection.fetch({
      reset: true,
      data: $.param({'sort_order': {'created_at': 'desc'}, 'any_of_types': ['media_upload']}),
      success: function() {
        collectionFetched.resolve();
      }
    });

    collectionFetched.done(function() {
      var view;
      view = new App.Views.UploadsIndex({
        collection: collection
      });
      return $('#uploads').html(view.render().el);
    });
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
    var _this           = this,
      collection        = new App.Collections.Documents(),
      collectionFetched = new $.Deferred,
      userUid           = $('#documents').data('user-uid');

    collection.fetch({
      reset: true,
      data: $.param({
        'sort_order': {'published_at': 'desc'},
        'user_id': userUid,
        'any_of_status': [1]
      }),
      success: function() {
        collectionFetched.resolve();
      }
    });

    collectionFetched.done(function() {
      var view;
      view = new App.Views.DocumentsIndex({
        collection: collection
      });
      return $('#documents').html(view.render().el);
    });
  }

});