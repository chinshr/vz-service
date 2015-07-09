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

/* Share popovers */
$(document).ready(function() {

  /* share button popover */
  $('#share-button').popover({
    container: 'body',
    html : true,
    trigger: 'manual',
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
  }).click(function(e) {
    $('#share-button').tooltip('hide');
    /* close all other popovers except this */
    $('#share-button').not(this).popover('hide');
    $(this).popover('toggle');
  });

  $(document).click(function(e) {
    if (!$(e.target).is('#share-button, .popover-content, .popover-content input')) {
      $('#share-button').popover('hide');
    }
  });
});

/* Publish popovers */
$(document).ready(function() {

  /* share button popover */
  $('#publish-button').popover({
    container: 'body',
    html : true,
    trigger: 'manual',
    placement: 'bottom',
    template: '<div class="popover publish-popover" id="publish-popover"><div class="arrow"></div><div class="popover-content"></div></div>',
    title: function() {
      return $('#' + $(this).data('target') + " .popover-title").html();
    },
    content: function() {
      return $('#' + $(this).data('target') + " .popover-content").html();
    }
  }).on('shown.bs.popover', function(e) {
    // VZ.social.bind();
  }).click(function(e) {
    $('#publish-button').tooltip('hide');
    /* close all other popovers except this */
    $('#publish-button').not(this).popover('hide');
    $(this).popover('toggle');
  });

  $(document).click(function(e) {
    if (!$(e.target).is('#publish-button, .popover-content, .popover-content input')) {
      $('#publish-button').popover('hide');
    }
  });
});

/* Dropdowns */
$(document).ready(function() {
  $('.dropdown-toggle').dropdown();
});
