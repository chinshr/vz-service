//= require lib/WAAPISim/waapisim
//= require lib/wavesurfer/wavesurfer
//= require lib/wavesurfer/util
//= require lib/wavesurfer/webaudio
//= require lib/wavesurfer/mediaelement
//= require lib/wavesurfer/drawer
//= require lib/wavesurfer/drawer.canvas
//= require lib/wavesurfer/html-init
//= require lib/wavesurfer/plugin/wavesurfer.timeline
//= require lib/wavesurfer/plugin/wavesurfer.minimap
//= require lib/wavesurfer/plugin/wavesurfer.regions
//= require lib/quill/quill
//= require lib/quill/modules/segmentation
//= require lib/quill/modules/toolbar

/* simply-toast */
$.extend(true, $.notify.defaultOptions, {
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
  var options = {
    animation: true,
    placement: "bottom"
  };

  if (VZ.isOS()) {
    // tooltips not working on iOS
    // https://github.com/twbs/bootstrap/issues/16028
  } else {
    $('.btn-tlb, [data-toggle^=tooltip]').tooltip(options);
  }
});

/* Progress bar start */
NProgress.configure({
  showSpinner: false,
  trickleRate: 1,
  trickleSpeed: 800,
  speed: 500
});

NProgress.start();
