App.Routers.Dashboard = Backbone.Router.extend({
  routes: {
    '' : 'default'
  },

  default: function() {
    var view;
    this.collection = new App.Collections.Uploads();
    this.collection.fetch({data: $.param({'sort_order': {'created_at': 'desc'}})});
    view = new App.Views.UploadsIndex({collection: this.collection});
    return $('#uploads').html(view.render().el);
  }
});