var Toolbar, dom, _, Quill;

dom = Quill.require('dom');

Toolbar = (function() {
  Toolbar.DEFAULTS = {
    container: null
  };

  Toolbar.formats = {
    LINE: {
      'align': 'align',
      'bullet': 'bullet',
      'list': 'list'
    },
    SELECT: {
      'align': 'align',
      'background': 'background',
      'color': 'color',
      'font': 'font',
      'size': 'size'
    },
    TOGGLE: {
      'bold': 'bold',
      'bullet': 'bullet',
      'image': 'image',
      'italic': 'italic',
      'link': 'link',
      'list': 'list',
      'strike': 'strike',
      'underline': 'underline'
    },
    TOOLTIP: {
      'image': 'image',
      'link': 'link'
    }
  };

  function Toolbar(quill, options) {
    this.quill = quill;
    this.options = {};

    this.bind(options);
  }

  Toolbar.prototype.bind = function(options) {
    if (_.isString(options) || _.isElement(options)) {
      this.options = {
        container: options
      };
    } else if(!_.isEmpty(options)) {
      this.options = options;
    }

    if (this.options.container == null) {
      throw new Error('container required for toolbar', this.options);
    }

    this.container = _.isString(this.options.container) ? document.querySelector(this.options.container) : this.options.container;
    this.inputs = {};
    this.preventUpdate = false;
    this.triggering = false;

    _.each(this.quill.options.formats, (function(_this) {
      return function(name) {
        if (Toolbar.formats.TOOLTIP[name] != null) {
          return;
        }
        // console.log(name);
        return _this.initFormat(name, _.bind(_this._applyFormat, _this, name));
      };
    })(this));

    if (this.quill.listeners(Quill.events.SELECTION_CHANGE).length === 0) {
      this.quill.on(Quill.events.SELECTION_CHANGE, (function(_this) {
        return function(range) {
          if (range != null) {
            return _this.updateActive(range);
          }
        };
      })(this));
    }

    if (this.quill.listeners(Quill.events.TEXT_CHANGE).length === 0) {
      this.quill.on(Quill.events.TEXT_CHANGE, (function(_this) {
        return function() {
          return _this.updateActive();
        };
      })(this));
    }

    this.quill.onModuleLoad('keyboard', (function(_this) {
      return function(keyboard) {
        return keyboard.addHotkey([dom.KEYS.BACKSPACE, dom.KEYS.DELETE], function() {
          return _.defer(_.bind(_this.updateActive, _this));
        });
      };
    })(this));

    dom(this.container).addClass('ql-toolbar');
    if (dom.isIOS()) {
      dom(this.container).addClass('ios');
    }
  }

  Toolbar.prototype.initFormat = function(format, callback) {
    var eventName, input, selector;
    selector = ".ql-" + format;
    if (Toolbar.formats.SELECT[format] != null) {
      selector = "select" + selector;
      eventName = 'change';
    } else {
      eventName = 'click';
    }
    input = this.container.querySelector(selector);
    if (input == null) {
      return;
    }
    this.inputs[format] = input;
    return dom(input).on(eventName, (function(_this) {
      return function() {
        var range, value;
        value = eventName === 'change' ? dom(input).value() : !dom(input).hasClass('ql-active');
        _this.preventUpdate = true;
        _this.quill.focus();
        range = _this.quill.getSelection();
        if (range != null) {
          callback(range, value);
        }
        _this.preventUpdate = false;
        return true;
      };
    })(this));
  };

  Toolbar.prototype.setActive = function(format, value) {
    var $input, input, ref, selectValue;
    if (format === 'image') {
      value = false;
    }
    input = this.inputs[format];
    if (input == null) {
      return;
    }
    $input = dom(input);
    if (input.tagName === 'SELECT') {
      this.triggering = true;
      selectValue = $input.value(input);
      if (value == null) {
        value = (ref = $input["default"]()) != null ? ref.value : void 0;
      }
      if (Array.isArray(value)) {
        value = '';
      }
      if (value !== selectValue) {
        if (value != null) {
          $input.option(value);
        } else {
          $input.reset();
        }
      }
      return this.triggering = false;
    } else {
      return $input.toggleClass('ql-active', value || false);
    }
  };

  Toolbar.prototype.updateActive = function(range, formats) {
    var activeFormats;
    if (formats == null) {
      formats = null;
    }
    range || (range = this.quill.getSelection());
    if (!((range != null) && !this.preventUpdate)) {
      return;
    }
    // TODO
    activeFormats = this._getActive(range);
    return _.each(this.inputs, (function(_this) {
      return function(input, format) {
        if (!Array.isArray(formats) || formats.indexOf(format) > -1) {
          _this.setActive(format, activeFormats[format]);
        }
        return true;
      };
    })(this));
  };

  Toolbar.prototype._applyFormat = function(format, range, value) {
    if (this.triggering) {
      return;
    }
    if (range.isCollapsed()) {
      this.quill.prepareFormat(format, value, 'user');
    } else if (Toolbar.formats.LINE[format] != null) {
      this.quill.formatLine(range, format, value, 'user');
    } else {
      this.quill.formatText(range, format, value, 'user');
    }
    return _.defer((function(_this) {
      return function() {
        _this.updateActive(range, ['bullet', 'list']);
        return _this.setActive(format, value);
      };
    })(this));
  };

  Toolbar.prototype._getActive = function(range) {
    var leafFormats, lineFormats;
    leafFormats = this._getLeafActive(range);
    lineFormats = this._getLineActive(range);
    return _.defaults({}, leafFormats, lineFormats);
  };

  Toolbar.prototype._getLeafActive = function(range) {
    var contents, formatsArr, line, offset, ref;
    if (range.isCollapsed()) {
      ref = this.quill.editor.doc.findLineAt(range.start), line = ref[0], offset = ref[1];
      if (offset === 0) {
        contents = this.quill.getContents(range.start, range.end + 1);
      } else {
        contents = this.quill.getContents(range.start - 1, range.end);
      }
    } else {
      contents = this.quill.getContents(range);
    }
    // formatsArr = _.map(contents.ops, 'attributes');
    formatsArr = _.map(contents.ops, function(o) { return o.attributes; });
    return this._intersectFormats(formatsArr);
  };

  Toolbar.prototype._getLineActive = function(range) {
    var firstLine, formatsArr, lastLine, offset, ref, ref1;
    formatsArr = [];
    ref = this.quill.editor.doc.findLineAt(range.start), firstLine = ref[0], offset = ref[1];
    ref1 = this.quill.editor.doc.findLineAt(range.end), lastLine = ref1[0], offset = ref1[1];
    if ((lastLine != null) && lastLine === firstLine) {
      lastLine = lastLine.next;
    }
    while ((firstLine != null) && firstLine !== lastLine) {
      formatsArr.push(_.clone(firstLine.formats));
      firstLine = firstLine.next;
    }
    return this._intersectFormats(formatsArr);
  };

  Toolbar.prototype._intersectFormats = function(formatsArr) {
    return _.reduce(formatsArr.slice(1), function(activeFormats, formats) {
      var activeKeys, added, formatKeys, intersection, missing;
      if (formats == null) {
        formats = {};
      }
      activeKeys = Object.keys(activeFormats);
      formatKeys = formats != null ? Object.keys(formats) : {};
      intersection = _.intersection(activeKeys, formatKeys);
      missing = _.difference(activeKeys, formatKeys);
      added = _.difference(formatKeys, activeKeys);
      _.each(intersection, function(name) {
        if (Toolbar.formats.SELECT[name] != null) {
          if (Array.isArray(activeFormats[name])) {
            if (activeFormats[name].indexOf(formats[name]) < 0) {
              return activeFormats[name].push(formats[name]);
            }
          } else if (activeFormats[name] !== formats[name]) {
            return activeFormats[name] = [activeFormats[name], formats[name]];
          }
        }
      });
      _.each(missing, function(name) {
        if (Toolbar.formats.TOGGLE[name] != null) {
          return delete activeFormats[name];
        } else if ((Toolbar.formats.SELECT[name] != null) && !Array.isArray(activeFormats[name])) {
          return activeFormats[name] = [activeFormats[name]];
        }
      });
      _.each(added, function(name) {
        if (Toolbar.formats.SELECT[name] != null) {
          return activeFormats[name] = [formats[name]];
        }
      });
      return activeFormats;
    }, formatsArr[0] || {});
  };

  return Toolbar;

})();

Quill.registerModule('toolbar', Toolbar);