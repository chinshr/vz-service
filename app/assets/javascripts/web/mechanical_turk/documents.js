//= require underscore
//= require lib/WAAPISim/waapisim
//= require lib/wavesurfer/wavesurfer.min
//= require lib/wavesurfer/plugin/wavesurfer.timeline.min

var Player = (function() {
  var wavesurfer = Object.create(WaveSurfer);
  var handlers = {
    'toggle-play-pause': function (event) {
      if ($(event.target).hasClass('fa-play')) {
        $(event.target).addClass('fa-pause').removeClass('fa-play');
      } else {
        $(event.target).addClass('fa-play').removeClass('fa-pause');
      }
      wavesurfer.playPause();
    },

    'reset': function () {
      $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
      wavesurfer.stop();
    },

    'green-mark': function () {
      wavesurfer.mark({
        id: 'up',
        color: 'rgba(0, 255, 0, 0.5)',
        position: wavesurfer.getCurrentTime()
      });
    },

    'red-mark': function () {
      wavesurfer.mark({
        id: 'down',
        color: 'rgba(255, 0, 0, 0.5)',
        position: wavesurfer.getCurrentTime()
      });
    },

    'step-backward': function () {
      wavesurfer.skipBackward();
    },

    'step-forward': function () {
      wavesurfer.skipForward();
    },

    'toggle-mute': function () {
      wavesurfer.toggleMute();
    }
  };

  var keyboardEvents = [
    {key: 32, ctrlKey: false, altKey: false, metaKey: true, shiftKey: true, name: 'toggle-play-pause'},  // Shift+Cmd+Space
    {key: 37, ctrlKey: false, altKey: false, metaKey: true, shiftKey: true, name: 'step-backward'},      // Shift+Cmd+Left-Cursor
    {key: 39, ctrlKey: false, altKey: false, metaKey: true, shiftKey: true, name: 'step-forward'},       // Shift+Cmd+Right-Cursor
  ];

  var playerKeyboardHandler = function(event) {
    var match = _.where(keyboardEvents, {key: event.keyCode, ctrlKey: event.ctrlKey,
      metaKey: event.metaKey, shiftKey: event.shiftKey, altKey: event.altKey});
    // console.log(event.keyCode);
    if (match.length > 0) {
      var handler = handlers[match[0].name];
      event.preventDefault();
      handler && _.bind(handler, this)(event);
    }
  };

  var playerToolbarHandler = function(event) {
    var action = event.target.dataset && event.target.dataset.action;
    // console.log(action);
    if (action && action in handlers) {
      _.bind(handlers[action], this)(event);
    }
  };

  var adjustProtocol = function(url) {
    if (window.location.protocol === "https:") {
      return url.replace(/^http:/, 'https:');
    } else {
      return url;
    }
  }

  var init = function(chunk, opts) {
    var options = {
      container     : $('#waveform').get(0),  // document.querySelector('#waveform'),
      height        : 55,
      waveColor     : 'violet',
      progressColor : '#3f6169', // '#fff',
      loaderColor   : '#555',
      cursorColor   : '#5492ce',
      markerWidth   : 1,
      audioRate     : 1,
      normalize     : true,
      pixelRatio    : 2,
      backend:      'AudioElement',  // 'AudioElement', 'WebAudio', 'MediaElement'
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

    wavesurfer.on('loading', showProgress);
    wavesurfer.on('ready', hideProgress);
    wavesurfer.on('destroy', hideProgress);
    wavesurfer.on('error', hideProgress);

    // Play at once when ready
    // Won't work on iOS until you touch the page
    wavesurfer.on('ready', function onReady() {
      // wavesurfer.play();
    });

    // Do something when the clip is over
    wavesurfer.on('finish', function () {
      $(event.target).addClass('fa-play').removeClass('fa-pause');
    });

    /* Error handling */
    wavesurfer.on('error', function (err) {
      console.error(err);
    });

    wavesurfer.init(options);

    /* Not sure? */
    wavesurfer.backend.on('audioprocess', function onFinish(time) {
      if (time >= wavesurfer.getDuration() - 0.01) {
        $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
        wavesurfer.un('audioprogress', onFinish);
        wavesurfer.stop();
      }
    });

    /* Timeline plugin */
    wavesurfer.on('ready', function () {
      var timeline = Object.create(WaveSurfer.Timeline);
      timeline.init({
        wavesurfer: wavesurfer,
        container: "#wave-timeline",
        height: 20,
        notchPercentHeight: 50
      });
    });

    // console.log('stream URL -> ' + chunk.track.mp3_stream_url);
    wavesurfer.util.ajax({
      responseType: 'json',
      url: adjustProtocol(chunk.track.waveform_json_stream_url)
      //url: chunk.track.waveform_json_stream_url
    }).on('success', function (data) {
      // console.log(data.left);
      wavesurfer.load(
        adjustProtocol(chunk.track.mp3_stream_url),
        data.left
      );
    });

    // wavesurfer.load(chunk.track.mp3_stream_url);
    // wavesurfer.load("http://localhost:3000/samples/i-like-pickles.wav");

    $(document).on('click', _.bind(playerToolbarHandler, this));
    $(document).on('keydown', _.bind(playerKeyboardHandler, this));
    // $('.player-play-pause').on('click', function() { wavesurfer.playPause(); });
  };

  return {
    init: init
  };
})();

$(function() {
//  $('.btn-tlb').tooltip();
  if (typeof(chunk) !== 'undefined') {
    Player.init(chunk);
  }
});