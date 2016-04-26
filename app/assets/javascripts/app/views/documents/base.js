App.Views.DocumentsBase = Backbone.View.extend({
  events: {
  },

  handlers: {
    'toggle-play-pause': function (event) {
      event.preventDefault();
      this.playPause();
    },

    'step-backward': function () {
      this.wavesurfer.skipBackward();
    },

    'step-forward': function () {
      this.wavesurfer.skipForward();
    },

    'playback-rate-down': function (event) {
      var value;
      if (value = $("#playback-speed-slider").slider("getValue")) {
        value -= 0.5;
        if (value >= 0.5) {
          this.wavesurfer.backend.setPlaybackRate(value);
          $("#playback-speed-slider").slider("setValue", value);
          $("#playback-speed-btn p").html(this.floatToFraction(value));
        }
      }
    },

    'playback-rate-up': function (event) {
      var value;
      if (value = $("#playback-speed-slider").slider("getValue")) {
        value += 0.5;
        if (value <= 3) {
          this.wavesurfer.backend.setPlaybackRate(value);
          $("#playback-speed-slider").slider("setValue", value);
          $("#playback-speed-btn p").html(this.floatToFraction(value));
        }
      }
    },

    'reset': function () {
      this.stopPlaying();
      this.clearSegmentHighlights();
    },

    'toggle-mute': function (event) {
      var target = $('.player-mute-toggle');
      if ($(target).hasClass('fa-volume-off')) {
        $(target).addClass('fa-volume-up').removeClass('fa-volume-off');
      } else {
        $(target).addClass('fa-volume-off').removeClass('fa-volume-up');
      }
      this.wavesurfer.toggleMute();
    },

    'toggle-resize': function (event) {
      var target = $('.player-resize-toggle');
      if ($(target).hasClass('fa-compress')) {
        // compress
        $(target).addClass('fa-expand').removeClass('fa-compress');
        $('body').addClass('waveform-hidden').removeClass('waveform-visible');
        // Backbone.history.navigate('?wf=0', {trigger: false});
      } else {
        // expand
        $(target).addClass('fa-compress').removeClass('fa-expand');
        $('body').addClass('waveform-visible').removeClass('waveform-hidden');
        // Backbone.history.navigate('?wf=1', {trigger: false});
      }
      this.redrawWaveform();
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

    'save': function () {
      this.save();
    },
  },

  keyboardEvents: [
    {name: 'toggle-play-pause', key: 27, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},  // Esc
    {name: 'reset', key: 27, ctrlKey: false, altKey: false, metaKey: false, shiftKey: true},  // Shift + Esc
    {name: 'step-backward', key: 112, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},      // F1
    {name: 'step-forward', key: 113, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},       // F2
    {name: 'playback-rate-down', key: 114, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},       // F3
    {name: 'playback-rate-up', key: 115, ctrlKey: false, altKey: false, metaKey: false, shiftKey: false},       // F4
    {name: 'save', key: 83, ctrlKey: false, altKey: false, metaKey: true, shiftKey: true},               // Shift+Cmd+S
  ],

  initialize: function() {
    _.bindAll(this, "publishDocument", "playPause", "stopPlaying",
      "setMediaElementTitle");
    $(document).on('click', _.bind(this.playerToolbarHandler, this));
    $(document).on('keydown', _.bind(this.playerKeyboardHandler, this));
    // $(window).on('resize', _.bind(this.redrawWaveform, this))

    this.model.fetch({
      success: (function(_this) {
        return function(model, response, options) {
          // console.log("=> fetched: success");
          _this.model.ok = true;
          _this.listenTo(_this.model, 'change', _this.saving);
          _this.render();
        }
      })(this),
      error: (function(_this) {
        return function(model, response, options) {
          // console.log("=> fetched: error");
          _this.model.ok = false;
          _this.model.errors = [{code: response.status, message: response.statusText}];
          _this.render();
        }
      })(this)
    });

    this.wavesurfer = Object.create(WaveSurfer);
  },

  waveHeight: 40,
  mapHeight: 15,

  initPlayer: function() {
    var options = {
      container     : '#waveform',  // document.querySelector('#waveform'),
      height        : this.waveHeight,
      waveColor     : '#ddd', // 'violet',
      progressColor : '#fff', // '#3f6169', // '#fff',
      loaderColor   : '#555',
      cursorColor   : '#5492ce',
      cursorWidth   : 2,
      audioRate     : 1,
      scrollParent  : true,
      normalize     : false,
      minimap       : true,
      minPxPerSec   : this.calcMinPixelsPerSec(this.waveHeight, this.mapHeight, this.getDevicePixelRatio()),
      pixelRatio    : this.getDevicePixelRatio(),
      // backend       : 'AudioElement',
      backend       : 'MediaElement',
      // backend       : 'WebAudio',
      fillParent    : true,
      hideScrollbar : false,
      dragSelection : false,
      loopSelection : false,
      interact      : true,
      splitChannels : false,
      skipLength    : 2,
      mediaType     : 'audio',
      mediaControls : false,
      barWidth      : 0,
      autoplay      : true,
      renderer      : 'MultiCanvas',
      maxCanvasWidth: 1000,
      autoCenter    : true
    };

    /* Init playback speed slider */
    this.initPlaybackSpeedSlider();

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
      window.clearInterval(loadingInterval);
      NProgress.done();
      $(".loading").removeClass("spinner");
      $(".play-pause").addClass("play");
    };

    var zipPeaks = function(data) {
      if ((data.left && data.left.length > 0) && (data.right && data.right.length > 0)) {
        // left + right channel filled
        return _.flatten(_.zip(data.left, _.map(data.right, function(n) { return -n; })));
      } else if ((data.left && data.left.length > 0) && ((!data.right) || (data.right && data.right.length === 0))) {
        // left filled + right empty
        return _.flatten(_.zip(data.left, _.map(data.left, function(n) { return -n; })));
      } else if (((!data.left) || (data.left && data.left.length === 0)) && (data.right && data.right.length > 0)) {
        // left empty + right filled
        return _.flatten(_.zip(data.right, _.map(data.right, function(n) { return -n; })));
      }
      return [];
    };

    var wrapPeaks = function(data) {
      if ((data.left && data.left.length > 0) && (data.right && data.right.length > 0)) {
        // left + right channel filled
        return [data.left, data.right];
      } else if ((data.left && data.left.length > 0) && ((!data.right) || (data.right && data.right.length === 0))) {
        // left filled + right empty
        return [data.left, data.left]
      } else if (((!data.left) || (data.left && data.left.length === 0)) && (data.right && data.right.length > 0)) {
        // left empty + right filled
        return [data.right, data.right];
      }
      return [];
    };

    var loadingProgress = 0;
    var loadingInterval = window.setInterval(function() {
      loadingProgress += 1;
      showProgress(Math.min(loadingProgress, 98));
    }, 250);

    this.wavesurfer.on('loading', showProgress);
    this.wavesurfer.on('destroy', hideProgress);
    this.wavesurfer.on('ready', hideProgress);
    this.wavesurfer.on('error', hideProgress);

    /* Load waveform and mp3 streams */
    this.wavesurfer.util.ajax({
      responseType: 'json',
      url: this.adjustProtocol(this.model.attributes.track.waveform_json_stream_url)
    }).on('success', _.bind(function (data) {
      this.wavesurfer.load(
        this.adjustProtocol(this.model.attributes.track.mp3_stream_url),
        // wrapPeaks(data)
        zipPeaks(data)
      );
    }, this));

    /* Update time */
    this.wavesurfer.on('seek', _.bind(function (e) {
      this.updatePlayTime();
    }, this));

    /* On finish */
    this.wavesurfer.on('finish', _.bind(function () {
      this.updatePlayTime();
      this.clearSegmentHighlights();
      this.stopPlaying();
    }, this));

    /* On error */
    this.wavesurfer.on('error', function (err) {
      console.error(err);
    });

    /* Regions */
    this.wavesurfer.enableDragSelection({
      color: this.randomColor(0.1)
    });

    this.wavesurfer.on('ready', _.bind(function onReady() {
      this.wavesurfer.pause();
      this.loadRegions();
      this.saveRegions();
      this.clearSegmentHighlights();
      this.updatePlayTime();
      this.setMediaElementTitle();
    }, this));

    this.wavesurfer.on('region-click', function (region, e) {
      e.stopPropagation();
      // Play on click, loop on shift click
      e.shiftKey ? region.playLoop() : region.play();
    });

    if (this.isEdit()) {
      this.wavesurfer.on('region-click', _.bind(this.editAnnotation, this));
      this.wavesurfer.on('region-updated', _.bind(this.updateRegion, this));
      this.wavesurfer.on('region-removed', _.bind(this.removeRegion, this));
    }

    this.wavesurfer.on('region-in', _.bind(this.highlightSegment, this));
    this.wavesurfer.on('region-out', _.bind(this.lowlightSegment, this));

    this.wavesurfer.on('region-play', _.bind(function (region) {
      region.once('out', _.bind(function () {
        this.wavesurfer.play(region.start);
        this.wavesurfer.pause();
      }, this));
    }, this));

    /* Minimap plugin */
    this.wavesurfer.initMinimap({
      height: this.mapHeight,
      waveColor: '#ddd',
      progressColor: '#999',
      cursorColor: '#5492ce',
      showRegions: false,
      showOverview: false,
      overviewBorderColor: '#aaa',
      overviewBorderSize: 1,
      scrollParent: true
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
        primaryFontColor: '#fff',
        secondaryFontColor: '#ccc',
        fontFamily: "'Lato', sans-serif",
        fontSize: 8
      });
    }, this));

    /* Play time */
    this.wavesurfer.on('play', _.bind(function (e) {
      this.playTimer();
      this.setPlayPageTitle();
    }, this));

    this.wavesurfer.on('pause', _.bind(function (e) {
      this.stopPlayTimer();
      this.updatePlayTime();
      this.resetPlayPageTitle();
    }, this));

    this.wavesurfer.on('finish', _.bind(function (e) {
      this.stopPlayTimer();
      this.updatePlayTime();
    }, this));

    /* Old mark region */
    /*
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
    */

    /* Not sure? */
    /*
    this.wavesurfer.backend.on('audioprocess', _.bind(function onFinish(time) {
      if (time >= this.wavesurfer.getDuration() - 0.01) {
        $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
        this.wavesurfer.un('audioprogress', onFinish);
        this.wavesurfer.stop();
      }
    }, this));
    */
  },

  initEditor: function() {
    this.titleEditor = new Quill(this.isEdit() ? '#title-editor' : '#title-editor', {
      'modules': {
        'authorship': {
          authorId: App.currentUser.attributes.username,
          enabled: this.isEdit()
        },
        'multi-cursor': this.isEdit()
      }
    });

    if (this.isShow()) {
      this.titleEditor.editor.disable();
    }

    this.titleEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        if (source == 'api') {
          // console.log("An API call triggered this change.");
        } else if (source == 'user') {
          _this.model.set({title: $.trim(this.getText())});
          //_this.saving();
        }
      };
    })(this));

    if (this.model.attributes.title) {
      // this.titleEditor.setText(this.model.attributes.title);  // v0.9.x
      this.titleEditor.setHTML(this.model.attributes.title);
    }

    this.contentEditor = new Quill(this.isEdit() ? '#content-editor' : '#content-editor', {
      'modules': {
        'authorship': {
          authorId: App.currentUser.attributes.username,
          enabled: this.isEdit()
        },
        'multi-cursor': this.isEdit(),
        'segmentation': { enabled: true },
        'toolbar': {
          container: '#content-editor-toolbar-template'
        }
      }
    });

    if (this.isEdit()) {
      this.titleEditorAuthorship    = this.titleEditor.getModule('authorship');
      this.titleEditorCursorManager = this.titleEditor.getModule('multi-cursor');
      this.contentEditorAuthorship    = this.contentEditor.getModule('authorship');
      this.contentEditorCursorManager = this.contentEditor.getModule('multi-cursor');
      this.contentEditorSegmentation = this.contentEditor.getModule('segmentation');
    }

    if (this.isShow()) {
      this.contentEditor.editor.disable();
    }

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
          // console.log("An API call triggered this change.");
        } else if (source == 'user') {
          // console.log(this.getContents());
          _this.model.set({rich_text: this.getContents()});
          // _this.model.set({html: $.trim(this.getHTML()), rich_text: this.getContents(), text: this.getText()});
        }
      };
    })(this));

    this.contentEditor.addContainer('spacer-container');
    this.contentEditor.onModuleLoad('toolbar', function(toolbar) {
      $('#content-editor iframe').contents().find('body').css('overflow', 'hidden');
    });

    this.titleEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        _this.moveUserInitials(this);
      }
    })(this));

    this.contentEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        _this.moveUserInitials(this);
      }
    })(this));

    this.titleEditor.on('selection-change', (function(_this) {
      return function(range) {
        if (range) {
          if (range.start == range.end) {
            // console.log('User cursor is on', range.start);
            _this.moveUserInitials(this, $('header').height() - 3);
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
            // TODO remove all popups
            // _this.hideContentEditorFormatPopover();
            _this.contentEditorFormatPopoverView.hide();
          } else {
            var text = _this.contentEditor.getText(range.start, range.end);
            // TODO show format popup
            console.log('User has highlighted', text);
            // _this.showContentEditorFormatPopover(this);
            _this.contentEditorFormatPopoverView.show(this);
          }
        } else {
          // TODO remove, this block is never reached
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
    return this.userInitial = new App.Views.DocumentsUserInitial({
      model: App.currentUser,
      parent: this
    });
  },

  initPlaybackSpeedSlider: function() {
    $("input.playback-speed-slider").slider({
      id: "playback-speed-slider-wrapper",
      min: 0.5,
      max: 3,
      step: 0.5,
      precision: 1,
      orientation: 'horizontal',
      value: 1,
      tooltip: 'hide',  // 'show' || 'hide' || 'always'
      handle: 'round',  // 'square' || 'triangle' || 'custom'
      // ticks: [0.5, 3],
    }).on('change', _.bind(function(e) {
      e.preventDefault();
      var value = e.value.newValue;
      // console.log(value);
      this.wavesurfer.backend.setPlaybackRate(value);
      $("#playback-speed-btn p").html(this.floatToFraction(value));
    }, this));
  },

  initContentEditorFormatPopover: function() {
    return this.contentEditorFormatPopoverView = new App.Views.DocumentsContentEditorFormatPopover({
      model: this.model,
      parent: this
    });
  },

  moveUserInitials: function(editor, margin) {
    margin = margin || ($('header').height() + 5);
    var sel = editor.root.ownerDocument.getSelection();
    if (sel && sel.rangeCount > 0) {
      var selrg = sel.getRangeAt(0);
      if (selrg) {
        var rects = selrg.getClientRects();
        if (rects.length > 0) {
          this.userInitial.moveY((-1 * margin) - (this.userInitial.height() / 2) + window.scrollY + rects[0].top);
        }
      }
    }
  },

  playerKeyboardHandler: function(event) {
    var match = _.where(this.keyboardEvents, {key: event.keyCode, ctrlKey: event.ctrlKey,
      metaKey: event.metaKey, shiftKey: event.shiftKey, altKey: event.altKey});
    // console.log(event.keyCode);
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

  playTimer: function() {
    this.stopPlayTimer();
    this.playTimerInterval = setInterval((function(_this) {
      return function() {
        _this.updatePlayTime();
      };
    })(this), 100);
  },

  updatePlayTime: function() {
    var elt = this.wavesurfer.getCurrentTime();
    var ttp = this.wavesurfer.getDuration() - elt;
    $('#elt').html(this.formatTime(elt));
    $('#ttp').html("-" + this.formatTime(ttp));
  },

  stopPlayTimer: function() {
    return window.clearInterval(this.playTimerInterval);
  },

  setPlayPageTitle: function() {
    if (navigator.userAgent.toLowerCase().indexOf('chrome') === -1) {
      // Chrome has it's built in title play indicator
      this.resetPlayPageTitle();
      $('title').html("▶ " + $('title').html());
    }
  },

  resetPlayPageTitle: function() {
    if (navigator.userAgent.toLowerCase().indexOf('chrome') === -1) {
      var title = $('title').html();
      $('title').html(title.replace("▶ ", ""));
    }
  },

  formatTime: function(number) {
    var h, m, s, f;
    number = Math.round(number * 10) / 10;
    number = (number).toString().split('.');
    s = parseInt(number[0]);
    f = parseInt(number[1] || '0');
    h = Math.floor(s / 3600);
    m = Math.floor((s % 3600) / 60);
    s = Math.floor((s % 3600) % 60);
    if (h > 0) {
      return sprintf("%.2d:%.2d:%.2d.%.1d", h, m, s, f);
    } else {
      return sprintf("%.2d:%.2d.%.1d", m, s, f);
    }
  },

  saving: function() {
    this.stopSaving();
    this.saveInterval = setInterval((function(_this) {
      return function() {
        // console.log("=> about to save.");
        return _this.save();
      };
    })(this), 1000);
  },

  stopSaving: function() {
    NProgress.done();
    return window.clearInterval(this.saveInterval);
  },

  save: function() {
    this.stopSaving();
    NProgress.start();
    this.model.sync('update', this.model, {
      success: (function(_this) {
        return function(data) {
          NProgress.done();
          $.notify("Document saved.", 'save');
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          NProgress.done();
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
    var regions, ops, regionCSS = [];

    // extract ops
    if (Object.prototype.toString.call(this.model.attributes.rich_text) === '[object Array]') {
      ops = this.model.attributes.rich_text;
    } else {
      ops = this.model.attributes.rich_text['ops'] || [];
    }

    // build segmented regions
    regions = ops.map(_.bind(function (op) {
      var region = {};
      if (op.attributes && op.attributes.segment) {
        var ts = this.parseSegmentTime(op.attributes.segment);
        var cs = this.parseSegmentColor(op.attributes.segment);
        region.id     = op.attributes.segment;
        region.start  = ts ? ts[0] : null;
        region.end    = ts ? ts[1] : null;
        // region.color  = cs || this.randomColor(0.3);
        region.color  = cs || App.Helpers.Color.rgbaColorFromUid(region.id, 0.3);
        region.resize = this.isEdit();
        region.drag   = this.isEdit();
      }
      return region;
    }, this));

    regions.forEach(_.bind(function (region) {
      if (!_.isEmpty(region)) {
        this.wavesurfer.addRegion(region);
        this.contentEditorSegmentation.addSegment(region.id, App.Helpers.Color.rgbaColorFromUid(region.id, 0.3));
        // regionCSS.push(".segment-" + region.id + " { background-color: " + App.Helpers.Color.rgbaColorFromUid(region.id, 0.3) + " !important; }");
      }
    }, this));

    // var style = document.createElement('style');
    // style.type = 'text/css';
    // style.innerHTML = regionCSS.join("\n");
    // document.getElementsByTagName('head')[0].appendChild(style);
  },

  updateRegion: function(region) {
    // console.log("updateRegion()", region);
    var uid = this.parseSegmentUid(region.id),
      contents = this.contentEditor.getContents(),
      changes = false;
    if (contents && contents.ops) {
      var _this = this;
      _.each(contents.ops, function(op) {
        if (op.attributes && op.attributes.segment === region.id) {
          var newId = _this.encodeSegmentFrom(region);
          if (newId !== region.id) {
            op.attributes.segment = newId;
            region.id = newId;
            changes = true;
          }
        }
      });
      if (changes) {
        this.clearSegmentHighlights();
        this.contentEditor.setContents(contents);
        this.model.set({rich_text: this.contentEditor.getContents()});
        this.highlightSegment(region);
      }
    }
  },

  removeRegion: function(region) {
    // console.log("removeRegion()", region);
  },

  saveRegions: function() {
    // console.log("saveRegions()");
  },

  editAnnotation: function(region) {
    // console.log("editAnnotation()");
  },

  clearSegmentHighlights: function() {
    // console.log("clearSegmentHighlights()");
    $("[class^=segment-]")
      .removeClass("hightlight-segment")
      .css({"background-color": ""});
  },

  highlightSegment: function(region) {
    var match;
    // console.log("highlightSegment()", region);
    this.clearSegmentHighlights();
    if (region && region.id) {
      match = $(".segment-" + this.jq(region.id))
        .addClass("segment-highlight");
        // .css({"background-color": region.color});
      $('html, body').animate({
        scrollTop: match.offset().top - ($('header').height() + $('.title-container').height() + 65)
      }, 500);
    }
  },

  lowlightSegment: function(region) {
    // console.log("lowlightSegment()");
    if (region && region.id) {
      $(".segment-" + this.jq(region.id))
        //.css({"background-color": ""});
        .removeClass("segment-highlight");
    }
  },

  jq: function(segment) {
    return segment.replace(/(:|\.|\+|\[|\]|,)/g, "\\$1");
  },

  randomColor: function(alpha) {
    return App.Helpers.Color.randomRgbaColor(alpha)
  },

  floatToFraction: function(number) {
    var half = "";
    var full = parseInt(number) < 1 ? "" : parseInt(number);
    if (Math.abs(parseInt(number) - number) > 0) {
      half = "½";
    }
    return "" + full + half + "×";
  },

  redrawWaveform: function() {
    if (this.wavesurfer) {
      this.wavesurfer.empty();
      this.wavesurfer.drawBuffer();
    }
  },

  // "c4ea2bad-6f84-4b6c-869b-8ddcd4128d83+t..." -> 'c4ea2bad-6f84-4b6c-869b-8ddcd4128d83'
  parseSegmentUid: function(segment) {
    um = segment.match(/^([a-z,0-9,-]*)(?![a-z,0-9,-])/);
    return um ? um[1] : null;
  },

  // "...+t1_45-3_52..." -> [1.45, 3.52]
  parseSegmentTime: function(segment) {
    var tm;
    tm = segment.match(/\+t([0-9_]*)-([0-9_]*)/);
    return tm ? _.map(tm.slice(1, 3), function(t) { return parseFloat(t.replace(/_/g, '.')); }) : null;
  },

  // "...+p12345678..." -> '12345678'
  parseSegmentProfile: function(segment) {
    var pm = segment.match(/\+p(.+?(?=(\+|$)))/);
    return pm ? pm[1] : null;
  },

  // "...+cafafaf..." -> 'afafaf'
  parseSegmentColor: function(segment) {
    var cm = segment.match(/\+c(.+?(?=(\+|$)))/);
    return cm ? cm[1] : null;
  },

  // "...+s0_75..." -> 0.75
  parseSegmentScore: function(segment) {
    var sm = segment.match(/\+s([0-9_]+?(?=(\+|$)))/);
    return sm ? parseFloat(sm[1].replace(/_/g, '.')) : null;
  },

  encodeSegmentFrom: function(region) {
    var sid, uid, time, score, color, profile;
    uid = this.parseSegmentUid(region.id);
    time = this.parseSegmentTime(region.id);
    score = this.parseSegmentScore(region.id);
    color = this.parseSegmentColor(region.id);
    profile = this.parseSegmentProfile(region.id);

    sid = uid;
    if (region.start && region.end) {
      sid = sid + "+t" + region.start.toFixed(2).toString().replace(/\./g, '_') + "-" + region.end.toFixed(2).toString().replace(/\./g, '_');
    } else {
      sid = sid + "+t" + time[0].toString().replace(/\./g, '_') + "-" + time[1].toString().replace(/\./g, '_');
    }

    if (score) {
      sid = sid + "+s" + score.toFixed(3).toString().replace(/\./g, '_');
    }

    if (color) {
      sid = sid + "+c" + color;
    }

    if (profile) {
      sid = sid + "+p" + profile;
    }

    return sid;
  },

  initSharePopover: function() {
    return this.sharePopoverView = new App.Views.PopoversShare({
      model: this.model,
      parent: this
    });
  },

  initPublishPopover: function() {
    return this.publishPopoverView = new App.Views.PopoversPublish({
      parent: this,
      callbacks: {
        publish: {
          success: this.publishDocument
        }
      }
    });
  },

  publishDocument: function() {
    this.stopSaving();
    NProgress.start();
    this.model.publish({ html: this.contentEditor.getHTML() }, {
      success: (function(_this) {
        return function(model) {
          NProgress.done();
          return window.location = window.location.origin + model.attributes.published_path;
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          NProgress.done();
          return $.notify("Error when saving document.", 'error');
        };
      })(this)
    });
  },

  initTagEditor: function() {
    $('.input-taggable').select2({
      minimumInputLength: 3,
      multiple: true,
      maximumInputLength: 30,
      tokenSeparators: [",", ".", "|"],
      ajax: {
        url: window.location.protocol + "//" + window.location.host + "/api/tags.json",
        dataType: 'json',
        type: 'GET',
        quietMillis: 100,
        data: function (term, page) { // page is the one-based page number tracked by Select2
          return {
            named_like: term, // search term
            most_used: 10, // page size
            offset: (page - 1) * 10 // page number
          };
        },
        results: function (data, page) {
          var results = [];
          $.each(data.tags, function(index, item){
            results.push({
              text: item.name,
              id: item.name  // item.id
            });
          });
          return {results: results, more: false};
        }
      },

      initSelection: function(el, callback) {
        var data = [];
        $(el.val().split(',')).each(function() {
          data.push({id: this, text: this});
        });
        callback(data);
      },

      createSearchChoice: function (term, data) {
        if ($(data).filter( function() {
          return this.text.localeCompare(term) === 0;
        }).length === 0) {
          return {id:term, text:term};
        }
      }
    }).on('change', (function(_this) {
      return function(event) {
        var tag_list = $(event.target).val();
        tag_list = tag_list.split(',');
        // console.log('tags current: ', _this.model.attributes);
        // console.log('tags new: ', tag_list);
        _this.model.set({tag_list: tag_list});
        // _this.saving();
      }
    })(this));
  },

  playPause: function() {
    if (this.wavesurfer.isPlaying()) {
      $(".play-pause").addClass("play").removeClass("pause");
    } else {
      $(".play-pause").addClass("pause").removeClass("play");
    }
    this.wavesurfer.playPause();
  },

  stopPlaying: function() {
    $(".play-pause").addClass("play").removeClass("pause");
    this.wavesurfer.stop();
  },

  showPageError: function() {
    $('#loading').hide();
    $('#document-load-error').show();
    $('.loading').removeClass('spinner');
  },

  setMediaElementTitle: function () {
    if (this.model) {
      $('audio').attr('title', this.model.attributes.title);
    }
  },

  isShow: function() { return false; },
  isEdit: function() { return false; },
  isPublish: function() { return false; }

});
_.extend(App.Views.DocumentsBase.prototype, App.Helpers.Player);
