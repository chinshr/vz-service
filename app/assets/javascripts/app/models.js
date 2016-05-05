// model mixins
App.Models.FormatDate = {
  timeOf: function(field) {
    return App.Helpers.DateFormatter.parse(this.get(field)) / 1000;
  },

  createdAt: function() {
    return this.timeOf("created_at");
  }
};

App.Models.MediaHelpers = {
  hasFinished: function() {
    // used for tile, overload in model
    return true;
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

  canEdit: function() {
    if (!this.hasFinished()) {
      return false;
    }
    if (this.attributes.privacy === 'private') {
      return false;
    }
    if (this.attributes.accessibility.indexOf('edit') > -1) {
      return true;
    }
    return false;
  },

  canShow: function() {
    if (!this.hasFinished()) {
      return false;
    }
    if (this.attributes.privacy === 'private') {
      return false;
    }
    if (this.attributes.accessibility.indexOf('view') > -1 || this.attributes.accessibility.indexOf('edit') > -1) {
      return true;
    }
    return false;
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

  showPath: function() {
    if (this.publishedPath()) {
      return this.publishedPath();
    } else {
      if (this.canEdit()) {
        return this.editPath();
      } else {
        return this.previewPath();
      }
    }
  },

  showURL: function() {
    var path = this.showPath();
    if (path) {
      return window.location.origin + path;
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

  imageSource: function(aspect, options) {
    var max    = _.max(_.pluck(this.attributes.images, 'iteration')),
      images   = _.filter(this.attributes.images, function(im) { return im.iteration === max; }),
      grouped  = _.groupBy(images, function(im) { return im.aspect_ratio; }),
      selected = grouped[aspect],
      sorted   = _.sortBy(selected, function(im) { return im.width + im.height; });

    if (sorted.length > 0) {
      return sorted[0].url;
    } else {
      return VZ.assets.thumb500x500;
    }
  },

  hexColor: function() {
   return App.Helpers.Color.hexColorFromModel(this);
  },

  rgbaColor: function() {
    return App.Helpers.Color.rgbaColorFromModel(this);
  },

  humanizeState: function(state) {
    state = state || this.attributes.state;
    if (typeof(this.attributes.status) === 'undefined') {
      // uploading
      switch (state) {
        // upload states
        case 'uploading':
        return "Uploading...";
        case 'completed':
        return "Processing...";
        case 'completing':
        return "Upload finishing";
        case 'error':
        return "Upload error.";
      }
    } else {
      // processing
      switch (state) {
        // ingest states
        case 'completed':  // spillover from uploading
        case 'starting':
        case 'started':
        return "Processing..."
        case 'finished':
        return "Finished"
        case 'stopping':
        return "Stopping..."
        case 'stopped':
        return "Stopped"
        case 'resetting':
        return "Resetting..."
        case 'reset':
        return "Reset"
        default:
        return "Working hard...";
      }
    }
  }

};