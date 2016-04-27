App.Helpers.Color = {

  hexColorFromModel: function(model) {
    return this.hexColorFromUid(model.attributes.uid);
  },

  rgbaColorFromModel: function(model, alpha) {
    if (model.attributes && model.attributes.uid) {
      return this.rgbaColorFromUid(model.attributes.uid, alpha);
    } else {
      return this.randomRgbaColor(alpha);
    }
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
        parseInt(str.slice(0, 2), 16) + "," +
        parseInt(str.slice(2, 4), 16) + "," +
        parseInt(str.slice(4, 6), 16) + "," + alpha + ")";
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