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

/* Dropdowns */
// $(document).ready(function() {
//   $('.dropdown-toggle').dropdown();
// });

/* Tooltips */
$(document).ready(function() {
  // $('.btn-tlb[data-toggle="tooltip"]').tooltip({});
  $('.btn-tlb').tooltip({});
  $('[data-toggle=tooltip]').tooltip({});
});

/* Popovers */
$(document).ready(function() {

  $(".btn-popover").each(function (index, btn) {
    var target;
    if (target = $(btn).data('target')) {
      target = $('#' + $(btn).data('target'));
      var poId = $(btn).data('popover-id');
      var poClass = $(btn).data('popover-class');

      $(btn).popover({
        container: 'body',
        html : true,
        trigger: 'manual',
        placement: 'bottom',
        template: '<div class="popover ' + poClass + '" id="' + poId + '"><div class="arrow"></div><div class="popover-content"></div></div>',
        content: function() {
          return target.html();
        }
      }).on('shown.bs.popover', function() {
        $(btn).tooltip('disable');
      })
      .on('hidden.bs.popover', function() {
        $(btn).tooltip('enable');
      });

      $(btn).on('click', function(e) {
        $(btn).tooltip('hide');
        /* close all other popovers except this */
        $(btn).not(this).popover('hide');
        $(btn).popover('toggle');
      });

      $(document).on('click', function(e) {
        if (!$(e.target).is($(btn)) && $(btn).find($(e.target)).length === 0 && $('#' + poId).find($(e.target)).length === 0) {
          $(btn).popover('hide');
        }
      });
    }
  });

});

/* Progress bar start */
NProgress.configure({
  showSpinner: false,
  trickleRate: 1,
  trickleSpeed: 800,
  speed: 500
});

NProgress.start();