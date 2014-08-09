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
    //$(".upload-panel").addClass("hover");
  }

  var removeOverlay = function(event) {
    event.originalEvent.preventDefault()
    event.originalEvent.stopPropagation()
    $("body").removeClass("hover");
    //$(".upload-panel").removeClass("hover");
  }
  
  // $('body').on('dragenter', addOverlay);
  //$('body').on('dragover', addOverlay);
  //$('body').on('dragend', removeOverlay)//.on('dragend', removeOverlay);
  
  var dropTarget = $('#drop-box'),
    body = $('body'),
    showDrag = false,
    timeout = -1;

  body.on('dragenter', function (event) {
    event.originalEvent.preventDefault()
    event.originalEvent.stopPropagation()
    body.addClass('hover');
    dropTarget.addClass('hover');
    showDrag = true; 
  }).on('dragover', function(event){
    event.originalEvent.preventDefault()
    event.originalEvent.stopPropagation()
    showDrag = true; 
  }).on('dragleave', function (event) {
    event.originalEvent.preventDefault()
    event.originalEvent.stopPropagation()
    showDrag = false; 
    clearTimeout( timeout );
    timeout = setTimeout(function() {
      if (!showDrag) { 
        dropTarget.removeClass('hover'); 
        body.removeClass('hover'); 
      }
    }, 200 );
  });
});
