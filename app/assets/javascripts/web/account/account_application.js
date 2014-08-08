$(function() {
  $('.input-single-searchable').chosen({});
  $('.input-taggable').select2({
    tags: function() { return ["red", "green", "blue"]},
    maximumInputLength: 15,
    tokenSeparators: [","]
  });

  // drop overlay
  var addOverlay = function(event) {
    event.originalEvent.preventDefault()
    event.originalEvent.stopPropagation()
    $("body").addClass("hover");
    $(".upload-panel").addClass("hover");
  }

  var removeOverlay = function(event) {
    event.originalEvent.preventDefault()
    event.originalEvent.stopPropagation()
    $("body").removeClass("hover");
    $(".upload-panel").removeClass("hover");
  }
  
  $('#drop-box').on('dragenter', addOverlay).on('drop', removeOverlay);
  $('#hover-overlay').on('dragleave', removeOverlay).on('dragend', removeOverlay).on('drop', removeOverlay);
  
  
});
