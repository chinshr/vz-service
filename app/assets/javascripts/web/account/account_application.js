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
  
  $(".upload-panel").hover(function() {
    // $("body").addClass("hover");
    $(this).addClass("hover");
  }, function() {
    $("body").removeClass("hover");
    $(this).removeClass("hover");
  });
  
  
  // show-panel hover
  $(".show-panel").hover(function() {
    $(this).find(".action-panel").addClass("hover");
  }, function() {
    $(this).find(".action-panel").removeClass("hover");
  });

  $("#files-proxy").bind("click", function() {
    $("#files").trigger("click");
  })
});

