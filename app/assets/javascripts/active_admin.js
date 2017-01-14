//= require active_admin/base
//= require underscore
//= require gmaps/google
//= require chartkick
//= require ace-rails-ap
//= require ace/theme-clouds

$(function() {
  $('.member_link[confirm]').on('click', function(e) {
    if (confirm($(this).attr('confirm'))) {
      // execute!
    } else {
      e.preventDefault();
    }
  });
});

$(function() {
  $(".ace-editor").each(function(index, el) {
    var elementId = $(el).attr("id");
    var fieldName = $(el).attr("name");
    var textarea = $('textarea#' + elementId);
    var form = textarea.closest('form');
    var editor = ace.edit(elementId);
    editor.setOptions({
      minLines: 10,
      maxLines: Infinity,
      tabSize: 2,
      useSoftTabs: true
    });
    editor.setTheme("ace/theme/clouds");
    textarea.css('visibility', 'hidden');
    editor.getSession().setMode("javascript");
    editor.getSession().setValue(textarea.val());
    form.submit(function() {
      textarea.val(editor.getSession().getValue());
      $(this).append(textarea);
    })
  });
});
