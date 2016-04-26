var Segmentation, Delta, Quill, _, dom;
dom = Quill.require('dom');
Delta = Quill.require('delta');

Segmentation = (function() {
  Segmentation.DEFAULTS = {
    //color: 'transparent',
    enabled: false
  };

  function Segmentation(quill, options) {
    this.quill = quill;
    this.options = options;
    if (this.options.button != null) {
      this.attachButton(this.options.button);
    }
    if (this.options.enabled) {
      this.enable();
    }
    this.quill.addFormat('segment', {
      "class": 'segment-'
    });
    this.quill.on(this.quill.constructor.events.PRE_EVENT, (function(_this) {
      return function(eventName, delta, origin) {
        var segmentDelta, segmentFormat;
        if (eventName === _this.quill.constructor.events.TEXT_CHANGE && origin === 'user') {
          segmentDelta = new Delta();
          segmentFormat = {};
          _.each(delta.ops, function(op) {
            if (op["delete"] != null) {
              return;
            }
            if ((op.insert != null) || ((op.retain != null) && (op.attributes != null))) {
              op.attributes || (op.attributes = {});
              return segmentDelta.retain(op.retain || op.insert.length || 1, segmentFormat);
            } else {
              return segmentDelta.retain(op.retain);
            }
          });
          return _this.quill.updateContents(segmentDelta, Quill.sources.SILENT);
        }
      };
    })(this));
    // this.addSegment(this.options.segmentId, this.options.color);
  }

  Segmentation.prototype.addSegment = function(id, color) {
    var styles;
    styles = {};
    styles[".segment-" + id] = {
      "background-color": "" + color
    };
    return this.quill.theme.addStyles(styles);
  };

  Segmentation.prototype.attachButton = function(button) {
    var $button;
    $button = dom(button);
    return $button.on('click', (function(_this) {
      return function() {
        $button.toggleClass('ql-on');
        return _this.enable($dom.hasClass('ql-on'));
      };
    })(this));
  };

  Segmentation.prototype.enable = function(enabled) {
    if (enabled == null) {
      enabled = true;
    }
    return dom(this.quill.root).toggleClass('segmentation', enabled);
  };

  Segmentation.prototype.disable = function() {
    return this.enable(false);
  };

  return Segmentation;

})();

Quill.registerModule('segmentation', Segmentation);
