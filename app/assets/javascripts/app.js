window.App = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
  initialize: function() {
    new App.Routers.Dashboard();
    Backbone.history.start();
  }
}

$(document).ready(function() {
  App.initialize();
});
  

