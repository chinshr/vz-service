//= require_self
//= require ./models
//= require ./router
//= require_tree ../../templates
//= require_tree ./helpers
//= require_tree ./models
//= require_tree ./collections
//= require ./views/popover_base
//= require_tree ./views/tiles
//= require_tree ./views

window.App = {
  Models: {},
  Collections: {},
  Views: {},
  Helpers: {},

  initialize: function() {
    var _this = this;
    Backbone.Validation.configure({
      labelFormatter: 'label'
    });

    this.router = new App.Router();
    if (!Backbone.history.start({ pushState: true })) {
      $(window).load(function() {
        _this.hidePageProgress();
      });
    }
  },

  hidePageProgress: function() {
    NProgress.done();
  }
};

$(function() {
  App.initialize();
});
