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
});

// popover
$(document).ready(function() {

  $('.xbtn-popover').popover({
    html: true,
    title: 'Hello',
    placement: 'bottom',
    content: '<button id="close-me">Close Me!</button>'
  });

  $('.btn-popover').popover({ 
    html : true, 
    placement: 'bottom',
    title: function() {
      return $('#' + $(this).data('target') + " .popover-title").html();
    },
    content: function() {
      return $('#' + $(this).data('target') + " .popover-content").html();
    }
  }).on('shown.bs.popover', function(e){
    $.alert("Hello@");
    // var popover = jQuery(this);
    // jQuery(this).parent().find('div.popover .close').on('click', function(e){
    //   popover.popover('hide');
    // });
  });

  // $('.xbtn-popover').popover('toggle');

});

// dropdown
$(document).ready(function() {
  $('.dropdown-toggle').dropdown();
});