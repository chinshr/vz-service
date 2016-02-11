App.Models.Upload = Backbone.Model.extend({
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

  canShareLink: function() {
    if (!this.hasFinished()) {
      return false;
    }
    if (this.attributes.privacy === 'private') {
      return false;
    }
    if (this.publishedPath()) {
      return true;
    }
    if (this.attributes.accessibility.indexOf('view') > -1 || this.attributes.accessibility.indexOf('edit') > -1) {
      return true;
    }
    return false;
  },

  hasFinished: function() {
    return this.attributes.status === 9 ? true : false
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

  statusMessage: function () {
    switch (this.attributes.status) {
      case 0:
      return "Uploaded.";
      case 1:
      return "Processing starting.";
      case 2:
      return "Processing.";
      case 3:
      return "Stopping.";
      case 4:
      return "Stopped.";
      case 5:
      return "Resetting.";
      case 6:
      return "Reset.";
      case 7:
      return "Removing.";
      case 8:
      return "Removed.";
      case 9:
      return "Finished.";
      default:
      return "Uploading."
    }
  },

  publish: function(attributes, options) {
    if (attributes && typeof(attributes) === 'object') {
      attributes.event = 'publish';
    }
    // TODO: Need to find a way to publish from upload model!
    this.save(attributes, options);
  },

  imageSource: function(aspect, options) {
    var max    = _.max(_.pluck(this.attributes.images, 'iteration')),
      images   = _.filter(this.attributes.images, function(im) { return im.iteration === max; }),
      grouped  = _.groupBy(images, function(im) { return im.aspect_ratio; }),
      selected = grouped[aspect],
      sorted   = _.sortBy(selected, function(im) { return im.width + im.height; });

    if (sorted.length > 0) {
      return sorted[0].url;
    } else {
      return "/assets/bg/wf-icon-white-500x500.png";
    }
  },

  hexColor: function() {
    var str = this.attributes.slug_id;
    if (!!str) {
      return "#" + str.charCodeAt(0).toString(16) +
        str.charCodeAt(1).toString(16) +
        str.charCodeAt(2).toString(16);
    }
  },

  rgbaColor: function() {
    var str = this.attributes.slug_id;
    if (!!str) {
      return "rgba(" +
        str.charCodeAt(0) + "," +
        str.charCodeAt(1) + "," +
        str.charCodeAt(2) + ",.7)";
    }
  }


}, {className: 'Upload'});