//= require_self
//= require_tree ../../templates
//= require_tree ./helpers
//= require_tree ./models
//= require_tree ./collections
//= require ./views/popover_base
//= require_tree ./views
//= require_tree ./routers

window.App = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
  Helpers: {},

  initialize: function() {
    Backbone.Validation.configure({
      labelFormatter: 'label'
    });

    if (window.location.pathname == "/dashboard") {
      new App.Routers.Dashboard();
      Backbone.history.start({pushState: !!(window.history && history.pushState), root: "/dashboard"});
    } else {
      new App.Routers.Documents();
      Backbone.history.start({pushState: !!(window.history && history.pushState), root: "/documents"});
    }
  }
}

$(document).ready(function() {
  App.initialize();
});
