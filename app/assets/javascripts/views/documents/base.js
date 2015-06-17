App.Views.DocumentsBase = Backbone.View.extend({
  events: {},

  handlers: {
    'toggle-play-pause': function (event) {
      if ($(event.target).hasClass('fa-play')) {
        $(event.target).addClass('fa-pause').removeClass('fa-play');
      } else {
        $(event.target).addClass('fa-play').removeClass('fa-pause');
      }
      this.wavesurfer.playPause();
    },

    'reset': function () {
      $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
      this.wavesurfer.stop();
    },

    'green-mark': function () {
      this.wavesurfer.mark({
        id: 'up',
        color: 'rgba(0, 255, 0, 0.5)',
        position: this.wavesurfer.getCurrentTime()
      });
    },

    'red-mark': function () {
      this.wavesurfer.mark({
        id: 'down',
        color: 'rgba(255, 0, 0, 0.5)',
        position: this.wavesurfer.getCurrentTime()
      });
    },

    'step-backward': function () {
      this.wavesurfer.skipBackward();
    },

    'step-forward': function () {
      this.wavesurfer.skipForward();
    },

    'toggle-mute': function () {
      this.wavesurfer.toggleMute();
    },

    'toggle-playback-rate': function (event) {
      if (this.wavesurfer.backend.playbackRate > 1.0) {
        $(event.target).addClass('fa-angle-double-down').removeClass('fa-angle-down');
        this.wavesurfer.backend.setPlaybackRate(1);
      } else if (this.wavesurfer.backend.playbackRate == 1) {
        if ($(event.target).hasClass('fa-angle-double-up')) {
          $(event.target).addClass('fa-angle-down').removeClass('fa-angle-double-up').removeClass('fa-angle-douple-down');
          this.wavesurfer.backend.setPlaybackRate(1.25);
        } else if ($(event.target).hasClass('fa-angle-double-down')){
          $(event.target).addClass('fa-angle-up').removeClass('fa-angle-double-down').removeClass('fa-angle-douple-up');
          this.wavesurfer.backend.setPlaybackRate(0.75);
        }
      } else if (this.wavesurfer.backend.playbackRate < 1.0) {
        $(event.target).addClass('fa-angle-double-up').removeClass('fa-angle-up');
        this.wavesurfer.backend.setPlaybackRate(1);
      } else {
        $(event.target).addClass('fa-angle-double-up').removeClass('fa-angle-up').removeClass('fa-angle-douple-down').removeClass('fa-angle-douple-up');
        this.wavesurfer.backend.setPlaybackRate(1);
      }
    },
    'save': function () {
      this.save();
    },
  },

  keyboardEvents: [
    {name: 'toggle-play-pause', key: 27, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},  // Esc
    {name: 'reset', key: 27, ctrlKey: false, altKey: false, metaKey: false, shiftKey: true},  // Shift + Esc
    {name: 'step-backward', key: 112, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},      // F1
    {name: 'step-forward', key: 113, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},       // F2
    {name: 'save', key: 83, ctrlKey: false, altKey: false, metaKey: true, shiftKey: true},               // Shift+Cmd+S
  ],

  initialize: function() {
    $(document).on('click', _.bind(this.playerToolbarHandler, this));
    $(document).on('keydown', _.bind(this.playerKeyboardHandler, this));
    this.model.fetch({
      success: (function(_this) {
        return function(model, response, options) {
          console.log("=> fetched: success");
          _this.model.ok = true;
          _this.listenTo(_this.model, 'change', _this.saving);
          _this.render();
        }
      })(this),
      error: (function(_this) {
        return function(model, response, options) {
          console.log("=> fetched: error");
          _this.model.ok = false;
          _this.model.errors = [{code: response.status, message: response.statusText}];
          _this.render();
        }
      })(this)
    });

    this.wavesurfer = Object.create(WaveSurfer);
  },

  initPlayer: function() {
    var options = {
      container     : '#waveform',  // document.querySelector('#waveform'),
      height        : 30,
      waveColor     : '#ddd', // 'violet',
      progressColor : '#fff', // '#3f6169', // '#fff',
      loaderColor   : '#555',
      cursorColor   : '#5492ce',
      markerWidth   : 1,
      audioRate     : 1,
      scrollParent  : true,
      normalize     : true,
      minimap       : true,
      backend       : 'AudioElement'
    };

    /* Initialize wavesurfer */
    this.wavesurfer.init(options);

    /* Progress Bar */
    var progressDiv = document.querySelector('#player-progress-bar');
    var progressBar = progressDiv.querySelector('.progress-bar');

    var showProgress = function(percent) {
      progressDiv.style.display = 'block';
      progressBar.style.width = percent + '%';
    };

    var hideProgress = function () {
      progressDiv.style.display = 'none';
    };

    this.wavesurfer.on('loading', showProgress);
    this.wavesurfer.on('destroy', hideProgress);
    this.wavesurfer.on('ready', hideProgress);
    this.wavesurfer.on('error', hideProgress);

    /* Load waveform and mp3 streams */
    this.wavesurfer.util.ajax({
      responseType: 'json',
      url: this.adjustProtocol(this.model.attributes.track.waveform_json_stream_url)
    }).on('success', _.bind(function (data) {
      // console.log(data.left);
      this.wavesurfer.load(
        this.adjustProtocol(this.model.attributes.track.mp3_stream_url),
        data.left
      );
    }, this));

    /* On finish */
    this.wavesurfer.on('finish', function () {
      $(event.target).addClass('fa-play').removeClass('fa-pause');
    });

    /* On error */
    this.wavesurfer.on('error', function (err) {
      console.error(err);
    });

    /* Regions */
    this.wavesurfer.enableDragSelection({
      color: this.randomColor(0.1)
    });

    this.wavesurfer.on('ready', _.bind(function onReady() {
      this.loadRegions();
      this.saveRegions();
    }, this));

    this.wavesurfer.on('region-click', function (region, e) {
      e.stopPropagation();
      // Play on click, loop on shift click
      e.shiftKey ? region.playLoop() : region.play();
    });

    this.wavesurfer.on('region-click', this.editAnnotation);
    this.wavesurfer.on('region-updated', this.saveRegions);
    this.wavesurfer.on('region-removed', this.saveRegions);
    this.wavesurfer.on('region-in', this.highlightRegionChunk);

    this.wavesurfer.on('region-play', _.bind(function (region) {
      region.once('out', _.bind(function () {
        this.wavesurfer.play(region.start);
        this.wavesurfer.pause();
      }, this));
    }, this));

    /* Minimap plugin */
    this.wavesurfer.initMinimap({
      height: 20,
      waveColor: '#ddd',
      progressColor: '#999',
      // cursorColor: '#999'
      cursorColor: '#5492ce',
    });

    /* Timeline plugin */
    this.wavesurfer.on('ready', _.bind(function () {
      var timeline = Object.create(WaveSurfer.Timeline);
      timeline.init({
        wavesurfer: this.wavesurfer,
        container: "#waveform-timeline",
        height: 20,
        notchPercentHeight: 50,
        primaryColor: '#fff',
        secondaryColor: '#c0c0c0',
        primaryFontColor: '#ccc',
        secondaryFontColor: '#aaa',
        fontFamily: 'Arial',
        fontSize: 8
      });
    }, this));

    /* Old mark region */
    this.wavesurfer.on('mark', function (marker) {
      if (marker.timer) { return; }

      marker.timer = setTimeout(function () {
        var origColor = marker.color;
        marker.update({ color: 'yellow' });

        setTimeout(function () {
          marker.update({ color: origColor });
          delete marker.timer;
        }, 100);
      }, 100);
    });

    /* Not sure? */
    this.wavesurfer.backend.on('audioprocess', _.bind(function onFinish(time) {
      if (time >= this.wavesurfer.getDuration() - 0.01) {
        $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
        this.wavesurfer.un('audioprogress', onFinish);
        this.wavesurfer.stop();
      }
    }, this));

  },

  initEditor: function() {
    this.titleEditor = new Quill('#title-editor', {
      'modules': {
      },
      'styles': false // '/assets/web/quill-title-editor.css'
    });

    this.titleEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        if (source == 'api') {
          console.log("An API call triggered this change.");
        } else if (source == 'user') {
          _this.model.set({title: $.trim(this.getText())})
          //_this.saving();
        }
      };
    })(this));

    if (this.model.attributes.title) {
      // this.titleEditor.setText(this.model.attributes.title);  // v0.9.x
      this.titleEditor.setHTML(this.model.attributes.title);
    }

    this.contentEditor = new Quill('#content-editor', {
      'modules': {
        'toolbar': {
          container: '#content-editor-toolbar-container'
        },
      },
      'styles': false  // '/assets/web/quill-content-editor.css'
    });

    if (this.model.attributes.rich_text) {
      this.contentEditor.setContents(this.model.attributes.rich_text);
    } else if(this.model.attributes.html) {
      this.contentEditor.setHTML(this.model.attributes.html);
    } else if(this.model.attributes.text) {
      this.contentEditor.setText(this.model.attributes.text);
    }

    this.contentEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        if (source == 'api') {
          console.log("An API call triggered this change.");
        } else if (source == 'user') {
          _this.model.set({html: $.trim(this.getHTML()), rich_text: this.getContents(), text: this.getText()})
        }
      };
    })(this));

    this.contentEditor.addContainer('spacer-container');
    this.contentEditor.onModuleLoad('toolbar', function(toolbar) {
      $('#content-editor iframe').contents().find('body').css('overflow', 'hidden');
    });

    this.titleEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        // expand window
        // $('#title-editor').height(_this.titleEditor.root.ownerDocument.body.scrollHeight);
        _this.moveUserInitials(this, -75);
      }
    })(this));

    this.contentEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        // expand window
        // $('#content-editor').height(_this.contentEditor.root.ownerDocument.body.scrollHeight);
        _this.moveUserInitials(this);
      }
    })(this));

    this.titleEditor.on('selection-change', (function(_this) {
      return function(range) {
        if (range) {
          if (range.start == range.end) {
            // console.log('User cursor is on', range.start);
            _this.moveUserInitials(this, -75);
          } else {
            // var text = editor.getText(range.start, range.end);
            // console.log('User has highlighted', text);
          }
        } else {
          // console.log('Cursor not in the editor');
        }
      }
    })(this));

    this.contentEditor.on('selection-change', (function(_this) {
      return function(range) {
        if (range) {
          if (range.start == range.end) {
            // console.log('User cursor is on', range.start);
            _this.moveUserInitials(this);
          } else {
            // var text = editor.getText(range.start, range.end);
            // console.log('User has highlighted', text);
          }
        } else {
          // console.log('Cursor not in the editor');
        }
      }
    })(this));

    var contentEditorKeyboard = this.contentEditor.getModule('keyboard');
    var titleEditorKeyboard   = this.titleEditor.getModule('keyboard');
    for (var i = 0; i < this.keyboardEvents.length; i++) {
      var key = this.keyboardEvents[i];
      if (key.name && this.handlers[key.name]) {
        contentEditorKeyboard.addHotkey({key: key.key, metaKey: key.metaKey, shiftKey: key.shiftKey}, 
          _.bind(this.handlers[key.name], this));
        titleEditorKeyboard.addHotkey({key: key.key, metaKey: key.metaKey, shiftKey: key.shiftKey}, 
          _.bind(this.handlers[key.name], this));
      }
    }
  },

  initUserInitials: function() {
    var ui = $(".user-initials");
    if (ui.length !== 0 && !ui.is(':visible')) {
      ui.animate({top: 0, opacity: 1}, 'fast');
    }
  },

  moveUserInitials: function(editor, margin) {
    margin = margin || -86;
    var sel = editor.root.ownerDocument.getSelection();
    if (sel && sel.rangeCount > 0) {
      var selrg = sel.getRangeAt(0);
      if (selrg) {
        var rects = selrg.getClientRects();
        if (rects.length > 0) {
          var ui = $(".user-initials");
          ui.stop().animate({
            top: margin - (ui.height() / 2) + window.scrollY + rects[0].top
          }, 0);
        }
      }
    }
  },

  playerKeyboardHandler: function(event) {
    var match = _.where(this.keyboardEvents, {key: event.keyCode, ctrlKey: event.ctrlKey,
      metaKey: event.metaKey, shiftKey: event.shiftKey, altKey: event.altKey});
    console.log(event.keyCode);
    if (match.length > 0) {
      var handler = this.handlers[match[0].name];
      event.preventDefault();
      handler && _.bind(handler, this)(event);
    }
  },

  playerToolbarHandler: function (event) {
    var action = event.target.dataset && event.target.dataset.action;
    if (action && action in this.handlers) {
      _.bind(this.handlers[action], this)(event);
    }
  },

  saving: function() {
    this.stopSaving();
    this.saveInterval = setInterval((function(_this) {
      return function() {
        console.log("=> about to save.");
        return _this.save();
      };
    })(this), 1000);
  },

  stopSaving: function() {
    return window.clearInterval(this.saveInterval);
  },

  save: function() {
    this.stopSaving();
    this.model.sync('update', this.model, {
      success: (function(_this) {
        return function(data) {
          $.notify("Document saved.", 'save');
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          $.notify("Error when saving document.", 'error');
        };
      })(this)
    });
  },

  adjustProtocol: function(url) {
    if (window.location.protocol === "https:") {
      return url.replace(/^http:/, 'https:');
    } else {
      return url;
    }
  },

  loadRegions: function() {
    var regions, ops;

    // extract ops
    if (Object.prototype.toString.call(this.model.attributes.rich_text) === '[object Array]') {
      ops = this.model.attributes.rich_text;
    } else {
      ops = this.model.attributes.rich_text['ops'] || [];
    }

    // build regions
    regions = ops.map(_.bind(function (op) {
      var region = {};
      if (op.attributes) {
        region.id    = op.attributes.uid;
        region.start = op.attributes.start;
        region.end   = op.attributes.end;
        region.color = this.randomColor(0.3);
      }
      return region;
    }, this));


    regions.forEach(_.bind(function (region) {
      console.log(region);
      this.wavesurfer.addRegion(region);
    }, this));
  },

  saveRegions: function() {
    console.log("saveRegions()");
  },

  editAnnotation: function(region) {
    console.log("editAnnotation()");
  },

  highlightRegionChunk: function(region) {
    console.log("highlightRegionChunk()");
  },

  randomColor: function(alpha) {
    return 'rgba(' + [
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      alpha || 1
    ] + ')';
  }
});