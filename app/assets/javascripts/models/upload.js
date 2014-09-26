App.Models.Upload = Backbone.Model.extend({
  urlRoot: 'api/account/uploads',

  defaults: {
    "tag_list": []
  },

  validation: {
    title: {
      required: true
    }
  },

  set: function(attributes, options) {
    if (attributes && attributes.tag_list && _.isString(attributes.tag_list)) {
      attributes.tag_list = attributes.tag_list.split(',')
    }

    return Backbone.Model.prototype.set.call(this, attributes, options);
  },

/*
  validate: function(attrs, options) {
    // TODO: dirty hack to convert tag_list back to array
    if (attrs.tag_list) {
      attrs.tag_list = attrs.tag_list.split(',')
    }
  },
*/

  parse: function(response, options) {
    return response && response.upload ? response.upload : response;
  },

  toJSON: function() {
    return {
      upload: _.clone(this.attributes) 
    }
  },
  
  hasFinished: function() {
    return this.attributes.status === 9 ? true : false
  },

  hasStopped: function() {
    return this.attributes.status === 4 ? true : false
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

  message: function () {
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
    }
  }
});