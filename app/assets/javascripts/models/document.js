App.Models.Document = Backbone.Model.extend({
  urlRoot: '/api/documents',

  parse: function(response, options) {
    // Note: collections need to be treated differently because, they are not
    // wrapped as 'document', 'document':{'id':1, ...} vs. 'documents':[{'id':1,...}, {'id':2, ...}, ...]
    if (response && response.document) {
      return response.document
    };
  },

  toJSON: function() {
    return {
      upload: _.clone(this.attributes) 
    }
  },

}, {className: 'Document'});