window.App = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
  initialize: function() {
    if (window.location.pathname == "/dashboard") {
      new App.Routers.Dashboard();
      Backbone.history.start({pushState: !!(window.history && history.pushState), root: "/dashboard"});
    } else if (window.location.pathname.match(/^\/documents/) >= 0) {
      new App.Routers.Documents();
      Backbone.history.start({pushState: !!(window.history && history.pushState), root: "/documents"});
    }
  }
}

$(document).ready(function() {
  App.initialize();
});
