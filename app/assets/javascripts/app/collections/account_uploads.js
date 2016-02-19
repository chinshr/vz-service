App.Collections.AccountUploads = Backbone.Collection.extend({
  url: 'api/account/uploads',
  model: App.Models.Upload,

  parse: function(response, options) {
    return response.uploads;
  },

  sync: function() {
    var a;
    a = Backbone.sync.apply(this, arguments);
    return a;
  }

});
