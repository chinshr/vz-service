//= require lib/WAAPISim/waapisim
//= require lib/wavesurfer/wavesurfer.min
//= require lib/quill

/* simply-toast */
$.extend(true, $.notify.defaultOptions, {
  "align": "center",
  "offset": {
    "from": "top",
    "amount": 0
  },
  "align": "right",
  "delay": 2000,
  "type": "warning"
});

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
  });

});

// dropdown
$(document).ready(function() {
  $('.dropdown-toggle').dropdown();
});