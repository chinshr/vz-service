App.Collections.Uploads = Backbone.Collection.extend({
  url: 'api/account/uploads',
  model: App.Models.Upload,
  
  parse: function(response, options) {
    console.log("=> collection parse");
    return response.uploads;
  },
  
  sync: function() {
    console.log("=> sync");
    var a;
    a = Backbone.sync.apply(this, arguments);
    return a;
  }
  
});