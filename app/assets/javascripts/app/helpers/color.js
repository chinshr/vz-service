App.Helpers.Color = {

  hexColorFromModel: function(model) {
    return this.hexColorFromUid(model.attributes.slug_id);
  },

  rgbaColorFromModel: function(model, alpha) {
    return this.rgbaColorFromUid(model.attributes.slug_id, alpha);
  },

  hexColorFromUid: function(str) {
    if (!!str) {
      return "#" + str.charCodeAt(0).toString(16) +
        str.charCodeAt(1).toString(16) +
        str.charCodeAt(2).toString(16);
    }
  },

  rgbaColorFromUid: function(str, alpha) {
    if (!!str) {
      if (!alpha) {
        alpha = ".7"
      }
      return "rgba(" +
        str.charCodeAt(0) + "," +
        str.charCodeAt(1) + "," +
        str.charCodeAt(2) + "," + alpha + ")";
    }
  },

  randomRgbaColor: function(alpha) {
    return 'rgba(' + [
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      alpha || 1.0
    ] + ')';
  }

};