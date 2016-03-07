App.Models.Document = Backbone.Model.extend(_.extend(Backbone.Model, App.Models.MediaHelpers, {
  urlRoot: '/api/documents',

  parse: function(response, options) {
    // Note: collections need to be treated differently because, they are not
    // wrapped as 'document', 'document':{'id':1, ...} vs. 'documents':[{'id':1,...}, {'id':2, ...}, ...]
    if (response && response.document) {
      return response.document
    } else {
      return response;
    }
  },

  toJSON: function() {
    return {
      document: _.clone(this.attributes)
    }
  },

  publish: function(attributes, options) {
    if (attributes && typeof(attributes) === 'object') {
      attributes.event = 'publish';
    }
    this.save(attributes, options);
  },

  // E.g. "/@chinshr/un-cuento-de-hadas-sin-final-feliz-mmdqvdhihdct"
  publishedPath: function() {
    if (this.attributes.published_path) {
      return this.attributes.published_path;
    }
  },

  // E.g. "https://voyz.es/@chinshr/un-cuento-de-hadas-sin-final-feliz-mmdqvdhihdct"
  publishedURL: function() {
    if (this.attributes.published_path) {
      return document.location.origin + this.attributes.published_path;
    }
  },

  // E.g. "/d/abcd1234/edit"
  editPath: function() {
    return this.previewPath() + "/edit";
  },

  // E.g. "https://voyz.es/d/abcd1234/edit"
  editURL: function() {
    return this.previewURL() + "/edit";
  },

  // E.g. "/d/abcd1234"
  previewPath: function() {
    return '/d/' + this.attributes.slug_id;
  },

  // E.g. "https://voyz.es/d/abcd1234"
  previewURL: function() {
    return window.location.origin + '/d/' + this.attributes.slug_id;
  },

  hasProgress: function() {
    return false;
  }

}, {className: 'Document'}));
