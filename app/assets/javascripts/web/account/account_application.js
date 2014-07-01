$(function() {
  $('.input-single-searchable').chosen({});
  $('.input-taggable').select2({
    tags: function() { return ["red", "green", "blue"]},
    maximumInputLength: 15,
    tokenSeparators: [","]
  });
  
});

