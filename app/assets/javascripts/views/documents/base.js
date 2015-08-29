App.Views.DocumentsBase = Backbone.View.extend({
  events: {
  },

  handlers: {
    'toggle-play-pause': function (event) {
      var target = $('.player-play-pause');
      if ($(target).hasClass('fa-play')) {
        $(target).addClass('fa-pause').removeClass('fa-play');
      } else {
        $(target).addClass('fa-play').removeClass('fa-pause');
      }
      this.wavesurfer.playPause();
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
      $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
      this.wavesurfer.stop();
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
    $(document).on('click', _.bind(this.playerToolbarHandler, this));
    $(document).on('keydown', _.bind(this.playerKeyboardHandler, this));
    $(window).on('resize', _.bind(this.redrawWaveform, this))

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
      height        : 40,
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
    };

    var loadingProgress = 0;
    var loadingInterval = window.setInterval(function() {
      loadingProgress += 3;
      showProgress(Math.min(loadingProgress, 100));
      // console.log(loadingProgress);
    }, 100);

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

    /* Update time */
    this.wavesurfer.on('seek', _.bind(function (e) {
      this.updatePlayTime();
    }, this));

    /* On finish */
    this.wavesurfer.on('finish', _.bind(function () {
      $(event.target).addClass('fa-play').removeClass('fa-pause');
      this.updatePlayTime();
      this.clearSegmentHighlights();
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
      this.loadRegions();
      this.saveRegions();
      this.clearSegmentHighlights();
      this.updatePlayTime();
    }, this));

    this.wavesurfer.on('region-click', function (region, e) {
      e.stopPropagation();
      // Play on click, loop on shift click
      e.shiftKey ? region.playLoop() : region.play();
    });

    this.wavesurfer.on('region-click', _.bind(this.editAnnotation, this));
    this.wavesurfer.on('region-updated', _.bind(this.updateRegion, this));
    this.wavesurfer.on('region-removed', _.bind(this.removeRegion, this));
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
      height: 15,
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
    this.titleEditor = new Quill(this.isEdit() ? '#title-editor' : '#title-editor',
      {
      'modules': {
      },
      'styles': false // '/assets/web/quill-title-editor.css'
    });

    if (this.isShow()) {
      this.titleEditor.editor.disable();
    }

    this.titleEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        if (source == 'api') {
          console.log("An API call triggered this change.");
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

    this.contentEditor = new Quill(this.isEdit() ? '#content-editor' : '#content-editor',
      {
      'modules': {
        'segmentation': { enabled: true },
        'toolbar': {
          container: '.content-editor-toolbar-container'
        },
      },
      'styles': false
    });

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
          console.log("An API call triggered this change.");
        } else if (source == 'user') {
          console.log(this.getContents());
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
        // expand window
        // $('#title-editor').height(_this.titleEditor.root.ownerDocument.body.scrollHeight);
        _this.moveUserInitials(this, $('header').height());
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
            _this.moveUserInitials(this, $('header').height() + 5);
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
            console.log('User cursor is on', range.start);
            _this.moveUserInitials(this);
            // TODO remove all popups
            _this.hideContentEditorFormatPopover();
          } else {
            var text = _this.contentEditor.getText(range.start, range.end);
            // TODO show format popup
            console.log('User has highlighted', text);
            _this.showContentEditorFormatPopover(this);
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
    var ui = $(".user-initials");
    if (ui.length !== 0 && !ui.is(':visible')) {
      ui.animate({top: 0, opacity: 1}, 'fast');
    }
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
      console.log(value);
      this.wavesurfer.backend.setPlaybackRate(value);
      $("#playback-speed-btn p").html(this.floatToFraction(value));
    }, this));
  },

  initContentEditorFormatPopover: function() {
    $('#content-editor').popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: 'top',
      template: '<div class="popover content-editor-format-popover" id="content-editor-format-popover"><div class="arrow"></div><div class="popover-content toolbar-nav"></div></div>',
      content: function() {
        var ob = $('nav ul.content-editor-toolbar-container');
        // var nb = ob.clone().wrap('<div>').parent();
        var nb = ob.clone();
        nb.attr('id', 'foo');
        return nb.wrap('<div>').parent().html();
      }
    }).on('show.bs.popover', function(e) {
      // console.log("show popover");
    }).on('shown.bs.popover', _.bind(function(e) {
      // console.log("shown popover");
      /* override = unset `!important` */
      $('#content-editor-format-popover').each(function () {
        var style = this.style.cssText;
        style = style.replace(new RegExp('\\!important', 'g'), '');
        this.style.cssText = style;
      });
      /* re-bind toolbar */
      this.contentEditor.modules.toolbar.bind("#foo");
    }, this));

    // TODO: event `inserted.bs.popover` does not work in this
    // version of Bootstrap, following is a workaround to set
    // position before the popover is inserted into DOM.
    $('body').on('DOMNodeInserted', (function(_this) {
      return function (e) {
        if ($(e.target).attr("id") === 'content-editor-format-popover') {
          pos = _this.callback(e.target);
          $('#content-editor-format-popover').each(function () {
            this.style.setProperty('left', pos[0] + 'px', 'important');
            this.style.setProperty('top', pos[1] + 'px', 'important');
          });
        }
      }
    })(this));
  },

  showContentEditorFormatPopover: function(editor) {
    var sel = editor.root.ownerDocument.getSelection();
    if (sel && sel.rangeCount > 0) {
      var selrg = sel.getRangeAt(0);
      if (selrg) {
        var rects = selrg.getClientRects();
        if (rects.length > 0) {
          this.callback = (function(rect) {
            return function(popover) {
              var left = window.scrollX + rect.left + ((rect.right - rect.left) / 2) - ($(popover).width() / 2);
              var top  = window.scrollY + rect.top - $(popover).height() - 5;
              return [left, top];
            }
          })(rects[0]);

          var popover = $('#content-editor-format-popover');
          if (popover && popover.is(':visible')) {
            var pos = this.callback(popover);
            popover.stop().animate({
              left: pos[0],
              top: pos[1]
            }, 0);
          } else {
            // triggers event to position using callback
            $("#content-editor").popover("show");
          }
        }
      }
    }
  },

  hideContentEditorFormatPopover: function() {
    var popover = $('#content-editor-format-popover');
    if (popover && popover.is(':visible')) {
      $("#content-editor").popover("hide");
    }
  },

  moveUserInitials: function(editor, margin) {
    margin = margin || ($('header').height() + 15);
    var sel = editor.root.ownerDocument.getSelection();
    if (sel && sel.rangeCount > 0) {
      var selrg = sel.getRangeAt(0);
      if (selrg) {
        var rects = selrg.getClientRects();
        if (rects.length > 0) {
          var ui = $(".user-initials");
          ui.stop().animate({
            top: (-1 * margin) - (ui.height() / 2) + window.scrollY + rects[0].top
          }, 0);
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
        console.log("=> about to save.");
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
    var regions, ops;

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
        region.id    = op.attributes.segment;
        region.start = ts ? ts[0] : null;
        region.end   = ts ? ts[1] : null;
        region.color = cs || this.randomColor(0.3);
      }
      return region;
    }, this));


    regions.forEach(_.bind(function (region) {
      if (!_.isEmpty(region)) {
        console.log(region);
        this.wavesurfer.addRegion(region);
      }
    }, this));
  },

  updateRegion: function(region) {
    console.log("updateRegion()", region);

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
    console.log("removeRegion()", region);
  },

  saveRegions: function() {
    console.log("saveRegions()");
  },

  editAnnotation: function(region) {
    console.log("editAnnotation()");
  },

  clearSegmentHighlights: function() {
    // console.log("clearSegmentHighlights()");
    $('.segment-highlight').removeClass("segment-highlight");
  },

  highlightSegment: function(region) {
    console.log("highlightSegment()", region);
    this.clearSegmentHighlights();
    if (region && region.id) {
      var match;
      match = $(".segment-" + this.jq(region.id)).addClass("segment-highlight");
      $('html, body').animate({
        scrollTop: match.offset().top - ($('header').height() + $('.title-container').height() + 65)
      }, 500);
    }
  },

  lowlightSegment: function(region) {
    console.log("lowlightSegment()");
    if (region && region.id) {
      $(".segment-" + this.jq(region.id)).removeClass("segment-highlight");
    }
  },

  jq: function(segment) {
    return segment.replace(/(:|\.|\+|\[|\]|,)/g, "\\$1");
  },

  randomColor: function(alpha) {
    return 'rgba(' + [
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      alpha || 1
    ] + ')';
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
    return this.sharePopoverView = new App.Views.DocumentsSharePopover({
      model: this.model,
      parent: this
    });
  },

  initPublishPopover: function() {
    return this.publishPopoverView = new App.Views.DocumentsPublishPopover({
      model: this.model,
      parent: this
    });
  },

  publish: function() {
    this.stopSaving();
    NProgress.start();
    this.model.publish({ html: this.contentEditor.getHTML() }, {
      success: (function(_this) {
        return function(model) {
          NProgress.done();
          window.location = window.location.origin + model.attributes.published_path;
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

  initTagEditor: function() {
    $('.input-taggable').select2({
      minimumInputLength: 3,
      multiple: true,
      maximumInputLength: 15,
      tokenSeparators: [",", " ", ".", "|"],
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
              id: item.id,
              text: item.name
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

  isShow: function() { return false; },
  isEdit: function() { return false; },
  isPublish: function() { return false; }

});