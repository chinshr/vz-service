$(function() {
  $('.input-single-searchable').chosen({});
  $('.input-taggable').select2({
    tags: function() { return ["red", "green", "blue"]},
    maximumInputLength: 15,
    tokenSeparators: [","]
  });
  
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
