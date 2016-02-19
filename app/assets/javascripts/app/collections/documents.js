App.Collections.Documents = Backbone.Collection.extend({
  url: 'api/documents',
  model: App.Models.Document,

  parse: function(response, options) {
    return response.documents;
  },

  sync: function() {
    var a;
    a = Backbone.sync.apply(this, arguments);
    return a;
  }

});
