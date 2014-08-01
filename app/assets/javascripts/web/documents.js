//= require WAAPISim/waapisim
//= require wavesurfer/wavesurfer
//= require wavesurfer/webaudio
//= require wavesurfer/webaudio.buffer
//= require wavesurfer/webaudio.media
//= require wavesurfer/drawer
//= require wavesurfer/drawer.canvas
//= require quill

/* Tooltips */
$(document).ready(function() {
  $('.btn-tlb').tooltip({});
});

/* Quill Editor */
$(document).ready(function() {

  var titleEditor = new Quill('#title-editor', {
    'modules': {
    },
    'styles': '/assets/web/quill-title-editor.css'
  });

  var contentEditor = new Quill('#content-editor', {
    'modules': {
      'toolbar': {
        container: '#content-editor-toolbar-container'
      },
    },
    'styles': '/assets/web/quill-content-editor.css'
  });
  
  contentEditor.addContainer('spacer-container');
  contentEditor.onModuleLoad('toolbar', function(toolbar) {
    $('#content-editor iframe').contents().find('body').css('overflow', 'hidden');
  });
  contentEditor.on('text-change', function(delta, source) {
    // expand window
    $('#content-editor').height(contentEditor.root.ownerDocument.body.scrollHeight);
  });
  contentEditor.on('selection-change', function(range) {
    if (range) {
      if (range.start == range.end) {
        // console.log('User cursor is on', range.start);
        
        // move user-initials
        var sel = contentEditor.root.ownerDocument.getSelection();
        if (sel && sel.rangeCount > 0) {
          var selrg = sel.getRangeAt(0);
          if (selrg) {
            var rects = selrg.getClientRects();
            if (rects.length > 0) {
              var ui = $(".user-initials");
              ui.stop().animate({
                top: 105 - (ui.height() / 2) + rects[0].top
              }, 50);
            }
          }
        }
      } else {
        // var text = editor.getText(range.start, range.end);
        // console.log('User has highlighted', text);
      }
    } else {
      // console.log('Cursor not in the editor');
    }
  });
  
  var keyboard = contentEditor.getModule('keyboard');
  keyboard.addHotkey({key: 32, metaKey: true, shiftKey: true}, function(range) {
    console.log('user hit Shift+Cmd+Space');
    return true;   // return false will prevent other listeners from receiving the event
  });
  
});

/* player */
var wavesurfer = Object.create(WaveSurfer);

$(document).ready(function() {

  /* waveform load progress bar */
  (function () {
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
  }());
  
  wavesurfer.init({
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
  
  //wavesurfer.load('/samples/i-like-pickles.wav');
  wavesurfer.load('/samples/genesis-1-1-en-us.m4a');
  
  wavesurfer.backend.on('audioprocess', function onFinish(time) {
      if (time >= wavesurfer.getDuration() - 0.01) {
        $('.player-play-pause').addClass('fa-play').removeClass('fa-pause');
        wavesurfer.un('audioprogress', onFinish);
        wavesurfer.stop();
      }
  });
}); /* on document load */

// Play at once when ready
// Won't work on iOS until you touch the page
wavesurfer.on('ready', function () {
  // wavesurfer.play();
});

// Do something when the clip is over
wavesurfer.on('finish', function () {
  $(event.target).addClass('fa-play').removeClass('fa-pause');
});

// Bind buttons and keypresses
(function () {
  var eventHandlers = {
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
    },
    
    'toggle-playback-rate': function (event) {
      if (wavesurfer.backend.playbackRate > 1.0) {
        $(event.target).addClass('fa-angle-double-down').removeClass('fa-angle-down');
        wavesurfer.backend.setPlaybackRate(1);
      } else if (wavesurfer.backend.playbackRate == 1) {
        if ($(event.target).hasClass('fa-angle-double-up')) {
          $(event.target).addClass('fa-angle-down').removeClass('fa-angle-double-up').removeClass('fa-angle-douple-down');
          wavesurfer.backend.setPlaybackRate(1.25);
        } else if ($(event.target).hasClass('fa-angle-double-down')){
          $(event.target).addClass('fa-angle-up').removeClass('fa-angle-double-down').removeClass('fa-angle-douple-up');
          wavesurfer.backend.setPlaybackRate(0.75);
        }
      } else if (wavesurfer.backend.playbackRate < 1.0) {
        $(event.target).addClass('fa-angle-double-up').removeClass('fa-angle-up');
        wavesurfer.backend.setPlaybackRate(1);
      } else {
        $(event.target).addClass('fa-angle-double-up').removeClass('fa-angle-up').removeClass('fa-angle-douple-down').removeClass('fa-angle-douple-up');
        wavesurfer.backend.setPlaybackRate(1);
      }
    }
    
  };

  $(document).on('keydown', function (e) {
    var map = {
      32: 'toggle-play-pause',       // space
      37: 'step-backward',       // left
      39: 'step-forward'       // right
    };
    
    if (e.keyCode in map) {
      // alert(e.keyCode);
      var handler = eventHandlers[map[e.keyCode]];
      e.preventDefault();
      handler && handler(e);
    }
  });

  $('iframe').each(function (index, iframe) {
    var doc = iframe.contentWindow.document;
    
    $(doc).on('keydown', function (e) {
      var map = {
        32: 'toggle-play-pause',       // space
        37: 'step-backward',           // left
        39: 'step-forward'             // right
      };

      if (e.keyCode in map) {
        var handler = eventHandlers[map[e.keyCode]];
        e.preventDefault();
        handler && handler(e);
      }
    });
  });
  
  // key('ctrl+r', function(){ alert('stopped reload!'); return false });

  $(document).on('click', function (e) {
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

