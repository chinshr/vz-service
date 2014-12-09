App.Views.DocumentsEdit = Backbone.View.extend({
  template: JST['documents/edit'],

  events: {
    'keydown #document': 'playerKeyboardHandler',
  },

  initialize: function() {
    this.listenTo(this.model, 'change', this.render);

    this.model.fetch({
      success: (function(_this) {
        return function(model, response, options) {
          console.log("=> fetched: success");
          _this.model.ok = true;
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
      $('#document-loading').hide();
      $('#document-edit').show();
    } else if (this.model.errors) {
      $('#document-load-error').show();
    }

    return this;
  },

  initPlayer: function() {
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

    this.wavesurfer.init({
      container     : $('#waveform').get(0),  // document.querySelector('#waveform'),
      height        : 40,
      waveColor     : '#ddd', // 'violet',
      progressColor : '#fff', // '#3f6169', // '#fff',
      loaderColor   : '#555',
      cursorColor   : '#5492ce',
      markerWidth   : 1,
      audioRate     : 1,
      normalize     : true
    });

    this.wavesurfer.load(this.model.attributes.track.mp3_stream_url);

    this.wavesurfer.backend.on('audioprocess', function onFinish(time) {
      if (time >= wavesurfer.getDuration() - 0.01) {
        $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
        wavesurfer.un('audioprogress', onFinish);
        wavesurfer.stop();
      }
    });

    // Play at once when ready
    // Won't work on iOS until you touch the page
    this.wavesurfer.on('ready', function () {
      // wavesurfer.play();
    });

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

    wavesurfer.on('error', function (err) {
      console.error(err);
    });
  },

  initEditor: function() {
    this.titleEditor = new Quill('#title-editor', {
      'modules': {
      },
      'styles': '/assets/web/quill-title-editor.css'
    });

    this.contentEditor = new Quill('#content-editor', {
      'modules': {
        'toolbar': {
          container: '#content-editor-toolbar-container'
        },
      },
      'styles': '/assets/web/quill-content-editor.css'
    });

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

  playerKeyboardHandler: function(e) {
    var map = {
      // 32: 'toggle-play-pause',       // space  NOTE: took this out as it interfers on other pages
      // 37: 'step-backward',       // left
      // 39: 'step-forward'       // right
    };
    
    if (e.keyCode in map) {
      console.log(e.keyCode);
      var handler = this.wsHandlers[map[e.keyCode]];
      e.preventDefault();
      handler && handler(e);
    }
  },

  wsHandlers = {
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
});