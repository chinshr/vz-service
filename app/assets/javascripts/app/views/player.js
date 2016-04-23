App.Views.Player = Backbone.View.extend({
  template: JST['player'],

  events: {
    'click .open-fullscreen': 'maximize',
    'click .close-fullscreen': 'minimize',
    'click .btn-play-pause': 'togglePlay'
  },

  waveHeight: 40,
  mapHeight: 15,

  initialize: function(options) {
    _.bindAll(this, "render", "update", "show", "hide",
      "play", "stop", "pause", "togglePlay",
      "maximize", "minimize", "destroy", "fetchModel", "isReady",
      "initWavesurfer", "calcMinPixelsPerSec", "initSharePopover", "startPlayTimer", "updatePlayTime",
      "stopPlayTimer", "loadRegions",
      "highlightSegment", "lowlightSegment", "setMediaElementTitle");
    this.parent      = options.parent;
    this.holder      = options.holder;
    this.document_id = options.document_id;
    this.model       = options.model;
    this.callbacks   = options.callbacks || {};
    this.wavesurfer  = Object.create(WaveSurfer);
    this.fetchModel();
  },

  render: function(attributes) {
    var template = this.template({title: "", author: ""});
    this.setElement(template);

    $('body').append(this.$el);
    this.playerEl = this.$el.first();

    return this;
  },

  update: function() {
    var titleEl = this.$(".player-title"),
      url;

    if (this.model.canShareLink()) {
      if (this.model.publishedURL()) {
        url = this.model.publishedURL();
      } else if (this.model.editURL()) {
        url = this.model.editURL();
      } else if (this.model.showURL()) {
        url = this.model.showURL();
      }
    }

    // update title + link
    titleEl.html(this.model.attributes.title);
    titleEl.prop('title', this.model.attributes.title);
    titleEl.prop('href', url);

    // update image + link
    this.$(".player-thumb img").attr("src", this.model.imageSource(1));
    this.$(".player-thumb img").attr("style", "background-color: " + this.model.rgbaColor() + ";");
    this.$(".player-thumb").attr("href", url);

    // update share
    this.initSharePopover().render();
  },

  togglePlay: function() {
    var playPauseEl = this.$(".btn-play-pause");
    if (playPauseEl.hasClass("pause")) {
      this.pause();
    } else if (playPauseEl.hasClass("play")) {
      this.play();
    }
  },

  stop: function(callback) {
    var playPauseEl = this.$(".btn-play-pause");
    this.wavesurfer.stop();
    playPauseEl.addClass("play").removeClass("pause");
    if (this.callbacks && this.callbacks.stop) {
      this.callbacks.stop(this);
    }
    if (callback) {
      callback();
    }
  },

  play: function() {
    var playPauseEl = this.$(".btn-play-pause");
    this.wavesurfer.play();
    playPauseEl.addClass("pause").removeClass("play");
    if (this.callbacks && this.callbacks.play) {
      this.callbacks.play(this);
    }
  },

  pause: function() {
    var playPauseEl = this.$(".btn-play-pause");
    this.wavesurfer.pause();
    playPauseEl.addClass("play").removeClass("pause");
    if (this.callbacks && this.callbacks.pause) {
      this.callbacks.pause(this);
    }
  },

  show: function() {
    this.playerEl.addClass('visible');
  },

  hide: function() {
    this.playerEl.removeClass('visible');
  },

  maximize: function() {
    this.playerEl.addClass("fullscreen");
  },

  minimize: function() {
    this.playerEl.removeClass("fullscreen");
  },

  destroy: function() {
    var _this = this;

    // this.wavesurfer.empty();
    this.wavesurfer.on('destroy', function() {
      _this.undelegateEvents();
      _this.$el.removeData().unbind();
      _this.remove();
      Backbone.View.prototype.remove.call(_this);
    });

    this.stop(function() {
      _this.wavesurfer.destroy();
    });
  },

  fetchModel: function() {
    var _this = this;
    if (this.model && this.model.attributes.id) {
      return;
    }
    this.model = new App.Models.Document({id: this.document_id});
    if (this.callbacks && this.callbacks.loading) {
      this.callbacks.hasCalledLoading = true;
      this.callbacks.loading(this);
    }
    this.model.fetch({
      success: function(model, response, options) {
        _.defer(function() {
          _this.update();
          _this.show();
          _this.initWavesurfer();
        });
      },
      error: function(model, response, options) {
        if (_this.callbacks && _this.callbacks.error && !_this.callbacks.hasCalledError) {
          _this.callbacks.hasCalledError = true;
          _this.callbacks.error(_this);
        }
      }
    });
  },

  isReady: function() {
    return !!this._isReady;
  },

  initWavesurfer: function() {
    var _this = this,
      options = {
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
      fillParent    : false,
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
      autoCenter    : true,
      maxCanvasWidth: 1000
    };

    /* Init playback speed slider */
    this.initPlaybackSpeedSlider();

    /* Initialize wavesurfer */
    this.wavesurfer.init(options);

    var loadingInterval;

    /* Progress Bar */
    var progressDiv = document.querySelector('#player-progress-bar');
    var progressBar = progressDiv.querySelector('.progress-bar');

    var showProgress = function(percent) {
      progressDiv.style.display = 'block';
      progressBar.style.width = percent + '%';
      _this.$(".loading").addClass("spinner");
    };

    var hideProgress = function () {
      progressDiv.style.display = 'none';
      window.clearInterval(loadingInterval);
      NProgress.done();
      _this.$(".loading").removeClass("spinner");
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
    loadingInterval = window.setInterval(function() {
      loadingProgress += 1;
      showProgress(Math.min(loadingProgress, 98));
    }, 250);

    var loading = function() {
      showProgress();
      if (_this.callbacks && _this.callbacks.loading && !_this.callbacks.hasCalledLoading) {
        _this.callbacks.hasCalledLoading = true;
        _this.callbacks.loading(_this);
      }
    };

    var destroy = function() {
      hideProgress();
      if (_this.callbacks && _this.callbacks.destroy && !_this.callbacks.hasCalledDestroy) {
        _this.callbacks.hasCalledDestroy = true;
        _this.callbacks.destroy(_this);
      }
    };

    var ready = function() {
      hideProgress();
      _this._isReady = true;
      if (_this.callbacks && _this.callbacks.ready && !_this.callbacks.hasCalledReady) {
        _this.callbacks.hasCalledReady = true;
        _this.callbacks.ready(_this);
      }
    };

    var error = function() {
      // hideProgress();
      if (_this.callbacks && _this.callbacks.error && !_this.callbacks.hasCalledError) {
        _this.callbacks.hasCalledError = true;
        _this.callbacks.error(_this);
      }
    };

    var finish = function() {
      if (_this.callbacks && _this.callbacks.finish && !_this.callbacks.hasCalledFinish) {
        _this.callbacks.hasCalledFinish = true;
        _this.callbacks.finish(_this);
      }
    };

    this.wavesurfer.on('loading', loading);
    this.wavesurfer.on('destroy', destroy);
    this.wavesurfer.on('ready', ready);
    this.wavesurfer.on('error', error);
    this.wavesurfer.on('finish', finish);

    /* Load waveform and mp3 streams */
    this.wavesurfer.util.ajax({
      responseType: 'json',
      url: this.adjustProtocol(this.model.attributes.track.waveform_json_stream_url)
    }).on('success', _.bind(function (data) {
      this.wavesurfer.load(
        this.adjustProtocol(this.model.attributes.track.mp3_stream_url),
        wrapPeaks(data)
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
      var _this = this;
      this.wavesurfer.pause();
      this.loadRegions();
      this.updatePlayTime();
      this.setMediaElementTitle();
      setTimeout(function() {
        if (VZ.os.ios) {
          _this.pause();
        } else {
          _this.play();
        }
      }, 0);
    }, this));

    this.wavesurfer.on('region-click', function (region, e) {
      e.stopPropagation();
      // Play on click, loop on shift click
      e.shiftKey ? region.playLoop() : region.play();
    });

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
      this.startPlayTimer();
    }, this));

    this.wavesurfer.on('pause', _.bind(function (e) {
      this.stopPlayTimer();
      this.updatePlayTime();
    }, this));

    this.wavesurfer.on('finish', _.bind(function (e) {
      this.stopPlayTimer();
      this.updatePlayTime();
    }, this));
  },

  initPlaybackSpeedSlider: function() {
  },

  initSharePopover: function() {
    return this.sharePopoverView = new App.Views.PopoversShare({
      parent: this,
      holder: this.$el.find('.btn-share'),
      placement: 'auto top'
    });
  },

  adjustProtocol: function(url) {
    if (window.location.protocol === "https:") {
      return url.replace(/^http:/, 'https:');
    } else {
      return url;
    }
  },

  startPlayTimer: function() {
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
    this.$('.player-time').html(this.formatTime(elt));
    this.$('.player-total-time').html("-" + this.formatTime(ttp));
  },

  stopPlayTimer: function() {
    return window.clearInterval(this.playTimerInterval);
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
        region.id     = op.attributes.segment;
        region.start  = ts ? ts[0] : null;
        region.end    = ts ? ts[1] : null;
        region.color  = cs || this.randomColor(0.3);
        region.resize = false;
        region.drag   = false;
      }
      return region;
    }, this));


    regions.forEach(_.bind(function (region) {
      if (!_.isEmpty(region)) {
        // console.log(region);
        this.wavesurfer.addRegion(region);
      }
    }, this));
  },

  highlightSegment: function(region) {
    console.log("highlightSegment()", region);
  },

  lowlightSegment: function(region) {
    console.log("lowlightSegment()");
  },

  randomColor: function(alpha) {
    return 'rgba(' + [
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      ~~(Math.random() * 255),
      alpha || 1
    ] + ')';
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

      calcMinPixelsPerSec: function(waveHeight, mapHeight, pixelRatio) {
      var availablePixels, height, duration,
        pixelsPerSec, maxCanvasWidth, maxCanvasArea;

        if (!pixelRatio) {
          pixelRatio = this.getDevicePixelRatio();
        }

        if (VZ.browser.chrome) {
          maxCanvasWidth = 32767;
          maxCanvasArea  = 16384 * 16384;
        } else if (VZ.browser.safari && !VZ.os.ios) {
          maxCanvasWidth = 32767;
          maxCanvasArea  = 16384 * 16384;
        } else if (VZ.browser.safari && VZ.os.ios) {
          maxCanvasWidth = 8192;
          maxCanvasArea  = 8192 * 8192;
        } else if (VZ.browser.gecko) {
          maxCanvasWidth = 32767;
          maxCanvasArea  = 22528 * 22528;
        } else if (VZ.browser.ie) {
          maxCanvasWidth = 8192;
          maxCanvasArea  = 8192 * 8192;
        } else {
          maxCanvasWidth = 4096;
          maxCanvasArea  = 4096 * 4096;
        }
        height          = this.waveHeight + this.mapHeight,
        duration        = this.model.attributes.track.duration; // in secs
        availablePixels = Math.min(maxCanvasWidth, maxCanvasArea / height);
        pixelsPerSec    = availablePixels / duration / pixelRatio;
        pixelsPerSec    = Math.min(50, Math.max(1, Math.floor(pixelsPerSec)));
        return pixelsPerSec;
    },

    getDevicePixelRatio: function() {
      var ratio = 1;
      // To account for zoom, change to use deviceXDPI instead of systemXDPI
      if (window.screen.systemXDPI !== undefined && window.screen.logicalXDPI       !== undefined && window.screen.systemXDPI > window.screen.logicalXDPI) {
        // Only allow for values > 1
        ratio = window.screen.systemXDPI / window.screen.logicalXDPI;
      } else if (window.devicePixelRatio !== undefined) {
        ratio = window.devicePixelRatio;
      }
      return ratio;
    },

    setMediaElementTitle: function () {
      if (this.model) {
        $('audio').attr('title', this.model.attributes.title);
      }
    }

});
_.extend(App.Views.Player.prototype, App.Helpers.Player);
