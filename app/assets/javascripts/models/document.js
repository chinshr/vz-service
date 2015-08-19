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
      document: _.clone(this.attributes)
    }
  },

  publish: function(attributes, options) {
    if (attributes && typeof(attributes) === 'object') {
      attributes.status = 1;
    }
    this.save(attributes, options);
  }

}, {className: 'Document'});