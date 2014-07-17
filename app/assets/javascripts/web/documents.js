//= require WAAPISim/waapisim
//= require wavesurfer/wavesurfer
//= require wavesurfer/webaudio
//= require wavesurfer/webaudio.buffer
//= require wavesurfer/webaudio.media
//= require wavesurfer/drawer
//= require wavesurfer/drawer.canvas


/* Quill Editor */
$(document).ready(function() {
  var titleEditor = new Quill('#title-editor', {
    modules: {
    },
    'styles': '/assets/web/quill-title-editor.css'
  });

  var contentEditor = new Quill('#content-editor', {
    modules: {
      'toolbar': {
        container: '#content-editor-toolbar-container'
      },
    },
    'styles': '/assets/web/quill-content-editor.css'
  });
});

/* player */

var wavesurfer = Object.create(WaveSurfer);

$(document).ready(function() {
  
  /* weaveform progress bar */
  (function () {
    var progressDiv = document.querySelector('#progress-bar');
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
  }());
  
  wavesurfer.init({
    container     : document.querySelector('#waveform'),
    height        : 40,
    waveColor     : '#ddd', // 'violet',
    progressColor : '#fff',
    loaderColor   : '#555',
    cursorColor   : '#5492ce', // '#3f6169',
    markerWidth   : 0.5,
    audioRate     : 2,
    normalize     : true
  });
  
  wavesurfer.load('/samples/i-like-pickles.wav');
  // wavesurfer.loadBlob('/samples/i-like-pickles.wav');
  
});

// Play at once when ready
// Won't work on iOS until you touch the page
wavesurfer.on('ready', function () {
  // wavesurfer.play();
});

// Do something when the clip is over
wavesurfer.on('finish', function () {
  console.log('Finished playing');
});

// Bind buttons and keypresses
(function () {
  var eventHandlers = {
    'play': function () {
      wavesurfer.playPause();
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

/*
  document.addEventListener('keydown', function (e) {
    var map = {
      32: 'play',       // space
      38: 'green-mark', // up
      40: 'red-mark',   // down
      37: 'back',       // left
      39: 'forth'       // right
    };
    if (e.keyCode in map) {
      var handler = eventHandlers[map[e.keyCode]];
      e.preventDefault();
      handler && handler(e);
    }
  });
*/

  document.addEventListener('click', function (e) {
    var action = e.target.dataset && e.target.dataset.action;
    if (action && action in eventHandlers) {
      eventHandlers[action](e);
    }
  });
}());

// Flash mark when it's played over
wavesurfer.on('mark', function (marker) {
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

// Drag'n'drop
/*
document.addEventListener('DOMContentLoaded', function () {
    var toggleActive = function (e, toggle) {
        e.stopPropagation();
        e.preventDefault();
        toggle ? e.target.classList.add('wavesurfer-dragover') :
            e.target.classList.remove('wavesurfer-dragover');
    };

    var handlers = {
        // Drop event
        drop: function (e) {
            toggleActive(e, false);

            // Load the file into wavesurfer
            if (e.dataTransfer.files.length) {
                wavesurfer.loadBlob(e.dataTransfer.files[0]);
            } else {
                wavesurfer.fireEvent('error', 'Not a file');
            }
        },

        // Drag-over event
        dragover: function (e) {
            toggleActive(e, true);
        },

        // Drag-leave event
        dragleave: function (e) {
            toggleActive(e, false);
        }
    };

    var dropTarget = document.querySelector('#drop');
    Object.keys(handlers).forEach(function (event) {
        dropTarget.addEventListener(event, handlers[event]);
    });
});
*/
