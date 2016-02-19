App.Models.Upload = Backbone.Model.extend(_.extend(Backbone.Model, App.Models.MediaHelpers, {
// App.Models.Upload = Backbone.Model.extend({
  urlRoot: 'api/account/uploads',

  defaults: {
    "tag_list": []
  },

  validation: {
    title: {
      required: function(value, attr, computedState) {
        // only on update
        return typeof(this.attributes.id) === 'undefined' ? false : true;
      }
    },

    source_url: {
      required: function(value, attr, computedState) {
        if (typeof(this.attributes.id) === 'undefined') {
          // only on create
          return _.isEmpty(this.attributes.s3_url) ? true : false;
        } else {
          // not on update
          return false;
        }
      },
      pattern: 'url'
    }
  },

  labels: {
    source_url: "Source URL"
  },

  set: function(attributes, options) {
    if (attributes && attributes.tag_list && _.isString(attributes.tag_list)) {
      attributes.tag_list = attributes.tag_list.split(',')
    }
    return Backbone.Model.prototype.set.call(this, attributes, options);
  },

  parse: function(response, options) {
    // Note: collections need to be treated differently because, they are not
    // wrapped as 'upload', 'upload':{'id':1, ...} vs. 'uploads':[{'id':1,...}, {'id':2, ...}, ...]
    var res = response && response.upload ? response.upload : response;
    // we want to modify some attributes
    for(var key in res) {
      if (res.hasOwnProperty(key)) {
        if (key === 'privacy' && _.isArray(res[key])) {
          res[key] = res[key].toString();
        }
      }
    }
    return res;
  },

  toJSON: function() {
    return {
      upload: _.clone(this.attributes)
    };
  },

  hasStopped: function() {
    return this.attributes.status === 4 ? true : false
  },

  isUploading: function() {
    return typeof(this.attributes.id) === 'undefined';
  },

  hasProgress: function() {
    switch (this.attributes.status) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 5:
      case 7:
      return true;
      default:
      return false;
    }
  },

  publish: function(attributes, options) {
    if (attributes && typeof(attributes) === 'object') {
      attributes.event = 'publish';
    }
    // TODO: Need to find a way to publish from upload model!
    this.save(attributes, options);
  },

  hasFinished: function() {
    return (this.attributes.status === 9 ? true : false);
  }

}, {className: 'Upload'}));
