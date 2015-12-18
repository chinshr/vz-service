window.App = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
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
