window.App = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
  initialize: function() {
    if (window.location.pathname == "/dashboard") {
      new App.Routers.Dashboard();
    } else if (window.location.pathname == "/documents") {
      new App.Routers.Documents();
    }
    
    if (!Backbone.History.started) {
      Backbone.history.start({pushState: !!(window.history && history.pushState), root: window.location.pathname});
    }
  }
}

$(document).ready(function() {
  App.initialize();
});
