App.Views.DocumentsEdit = Backbone.View.extend({
  template: JST['documents/edit'],

  events: {
//    'keydown #document': 'playerKeyboardHandler',
  },

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

  render: function() {
    this.$el.html(this.template(this.model.attributes));

    if (this.model.ok) {
      this.initEditor();
      this.initPlayer();
      $('#document-loading').hide();
      $('#document-edit').show();
    } else if (this.model.errors) {
      $('#loading').hide();
      $('#document-load-error').show();
    }

    return this;
  },

  initPlayer: function() {
    var options = {
      container     : $('#waveform').get(0),  // document.querySelector('#waveform'),
      height        : 40,
      waveColor     : '#ddd', // 'violet',
      progressColor : '#fff', // '#3f6169', // '#fff',
      loaderColor   : '#555',
      cursorColor   : '#5492ce',
      markerWidth   : 1,
      audioRate     : 1,
      normalize     : true
    };

    /* Progress Bar */
    var progressDiv = document.querySelector('#player-progress-bar');
    var progressBar = progressDiv.querySelector('.progress-bar');

    var showProgress = function (percent) {
      progressDiv.style.display = 'block';
      progressBar.style.width = percent + '%';
    };

    var hideProgress = function () {
      progressDiv.style.display = 'none';
    };

    this.wavesurfer.on('loading', showProgress);
    this.wavesurfer.on('ready', hideProgress);
    this.wavesurfer.on('destroy', hideProgress);
    this.wavesurfer.on('error', hideProgress);

    // Play at once when ready
    // Won't work on iOS until you touch the page
    this.wavesurfer.on('ready', _.bind(function onReady() {
      this.wavesurfer.play();
    }, this));

    // Do something when the clip is over
    this.wavesurfer.on('finish', function () {
      $(event.target).addClass('fa-play').removeClass('fa-pause');
    });

    // Flash mark when it's played over
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

    this.wavesurfer.on('error', function (err) {
      console.error(err);
    });

    this.wavesurfer.init(options);

    this.wavesurfer.backend.on('audioprocess', _.bind(function onFinish(time) {
      if (time >= this.wavesurfer.getDuration() - 0.01) {
        $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
        this.wavesurfer.un('audioprogress', onFinish);
        this.wavesurfer.stop();
      }
    }, this));

    console.log('stream URL -> ' + this.model.attributes.track.mp3_stream_url);
    this.wavesurfer.load(this.model.attributes.track.mp3_stream_url);
    // this.wavesurfer.load("http://localhost:3000/6s8l775jqc.128.mp3");
    // this.wavesurfer.load("http://localhost:3000/samples/i-like-pickles.wav");
    // this.wavesurfer.load("https://s3-eu-west-1.amazonaws.com/soundmites/f5/4779e0c3a111e3b368f97e5bff4d34/coincidence.mp3");
  },

  initEditor: function() {
    this.titleEditor = new Quill('#title-editor', {
      'modules': {
      },
      'styles': '/assets/web/quill-title-editor.css'
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

    this.contentEditor = new Quill('#content-editor', {
      'modules': {
        'toolbar': {
          container: '#content-editor-toolbar-container'
        },
      },
      'styles': '/assets/web/quill-content-editor.css'
    });

    this.contentEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        if (source == 'api') {
          console.log("An API call triggered this change.");
        } else if (source == 'user') {
          _this.model.set({content: $.trim(this.getHTML())})

          // _this.saving();
        }
      };
    })(this));

    this.contentEditor.addContainer('spacer-container');
    this.contentEditor.onModuleLoad('toolbar', function(toolbar) {
      $('#content-editor iframe').contents().find('body').css('overflow', 'hidden');
    });

    this.contentEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        // expand window
        $('#content-editor').height(_this.contentEditor.root.ownerDocument.body.scrollHeight);
        _this.moveUserInitials();
      }
    })(this));

    this.contentEditor.on('selection-change', (function(_this) {
      return function(range) {
        if (range) {
          if (range.start == range.end) {
            // console.log('User cursor is on', range.start);
            _this.moveUserInitials();
          } else {
            // var text = editor.getText(range.start, range.end);
            // console.log('User has highlighted', text);
          }
        } else {
          // console.log('Cursor not in the editor');
        }
      }
    })(this));

    var keyboard = this.contentEditor.getModule('keyboard');
    keyboard.addHotkey({key: 32, metaKey: true, shiftKey: true}, function(range) {
      console.log('user hit Shift+Cmd+Space');
      return true;   // return false will prevent other listeners from receiving the event
    });

  },

  moveUserInitials: function() {
    var sel = this.contentEditor.root.ownerDocument.getSelection();
    if (sel && sel.rangeCount > 0) {
      var selrg = sel.getRangeAt(0);
      if (selrg) {
        var rects = selrg.getClientRects();
        if (rects.length > 0) {
          var ui = $(".user-initials");
          ui.stop().animate({
            top: 100 - (ui.height() / 2) + rects[0].top
          }, 50);
        }
      }
    }
  },

  keyboardMap: [
    {key: 32, metaKey: true, shiftKey: true, action: 'toggle-play-pause'}
  ],

  eventHandlers: {
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
    }
  },

  playerKeyboardHandler: function(event) {
    var map = {
      // 32: 'toggle-play-pause',       // space  NOTE: took this out as it interfers on other pages
      // 37: 'step-backward',           // left
      // 39: 'step-forward'             // right
    };

    console.log("=> key: " + event.keyCode + " key");
    if (event.keyCode in map) {
      console.log("=> match: " + event.keyCode + " with '" + map[event.keyCode] + "'");
      var handler = this.eventHandlers[map[event.keyCode]];
      event.preventDefault();
      handler && _.bind(handler, this)(event);
    }
  },

  playerToolbarHandler: function (event) {
    var action = event.target.dataset && event.target.dataset.action;
    if (action && action in this.eventHandlers) {
      _.bind(this.eventHandlers[action], this)(event);
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
          $.notify("Document saved.");
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          $.notify("Error when saving document.", 'error');
        };
      })(this)
    });
  }
});