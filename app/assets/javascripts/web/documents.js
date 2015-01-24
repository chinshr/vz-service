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

  $('.btn-popover').popover({ 
    container: 'body',
    html : true,
    placement: 'bottom',
    title: function() {
      return $('#' + $(this).data('target') + " .popover-title").html();
    },
    content: function() {
      return $('#' + $(this).data('target') + " .popover-content").html();
    }
  }).on('shown.bs.popover', function(e) {
    VZ.social.bind();
/*
    var popover = jQuery(this);
    jQuery(this).parent().find('div.popover .close').on('click', function(e){
      popover.popover('hide');
    });
*/
  });

});

// dropdown
$(document).ready(function() {
  $('.dropdown-toggle').dropdown();
});