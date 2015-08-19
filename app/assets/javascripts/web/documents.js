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
  // $('.btn-tlb[data-toggle="tooltip"]').tooltip({});
  $('.btn-tlb').tooltip({});
});

/* Dropdowns */
$(document).ready(function() {
  $('.dropdown-toggle').dropdown();
});

/* Progress bar start */
NProgress.configure({
  showSpinner: false,
  trickleRate: 1,
  trickleSpeed: 800,
  speed: 500
});

NProgress.start();