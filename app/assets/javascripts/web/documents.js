//= require lib/WAAPISim/waapisim
//= require lib/wavesurfer/wavesurfer.min
//= require lib/wavesurfer/plugin/wavesurfer.minimap.min
//= require lib/wavesurfer/plugin/wavesurfer.regions.min
//= require lib/wavesurfer/plugin/wavesurfer.timeline.min
//= require lib/quill/quill
//= require lib/quill/modules/segmentation
//= require lib/quill/modules/toolbar

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
  $('.btn-tlb[data-toggle="tooltip"]').tooltip({});
});

/* Popovers */
$(document).ready(function() {

  /* share button popover */
  $('.btn-popover').popover({
    container: 'body',
    html : true,
    placement: 'bottom',
    template: '<div class="popover share-popover" id="share-popover"><div class="arrow"></div><div class="popover-content"></div></div>',
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

/* Dropdowns */
$(document).ready(function() {
  $('.dropdown-toggle').dropdown();
});

/* Sliders */
$(document).ready(function() {
});