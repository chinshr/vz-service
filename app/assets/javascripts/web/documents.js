//= require lib/WAAPISim/waapisim
//= require lib/wavesurfer/wavesurfer
//= require lib/wavesurfer/webaudio
//= require lib/wavesurfer/webaudio.buffer
//= require lib/wavesurfer/webaudio.media
//= require lib/wavesurfer/drawer
//= require lib/wavesurfer/drawer.canvas
//= require lib/quill

/* Tooltips */
$(document).ready(function() {
  $('.btn-tlb').tooltip({});
  $("#popoverExampleTwo").popover({
    html : true, 
    content: function() {
      return $('#popoverExampleTwoHiddenContent').html();
    },
    title: function() {
      return $('#popoverExampleTwoHiddenTitle').html();
    }
  });
});

// popover
$(document).ready(function() {

  $('.btn-popover').popover({
    html: true,
    title: 'Hello',
    placement: 'bottom',
    content: '<button id="close-me">Close Me!</button>'
  });

  $('.btn-popover').click(function() {
    $('#' + $(this).data('target')).toggle();
  });

});

// dropdown
$(document).ready(function() {
  $('.dropdown-toggle').dropdown();
});