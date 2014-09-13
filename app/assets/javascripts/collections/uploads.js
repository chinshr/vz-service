App.Collections.Uploads = Backbone.Collection.extend({
  url: 'api/account/uploads',
  model: App.Models.Upload
});
