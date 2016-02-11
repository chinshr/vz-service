App.Routers.Dashboard = Backbone.Router.extend({
  routes: {
    '' : 'index'
  },

  initialize: function() {
    this.collectionFetched = new $.Deferred;
    this.collection = new App.Collections.Uploads();
    this.collection.fetch({
      reset: true,
      data: $.param({'sort_order': {'created_at': 'desc'}, 'any_of_types': ['media_upload']}),
      success: (function(_this) {
        return function() {
          console.log("=> resolve");
          _this.collectionFetched.resolve();
        }
      })(this)
    });
  },

  index: function() {
    console.log('=> index');
    this.collectionFetched.done(
      (function(_this) {
        return function() {
          console.log('=> done');
          var view;
          view = new App.Views.UploadsIndex({collection: _this.collection});
          return $('#uploads').html(view.render().el);
        }
      })(this)
    );
  }
});