//= require active_admin/base

$(function() {
  $('.member_link[confirm]').on('click', function(e) {
    if (confirm($(this).attr('confirm'))) {
      // execute
    } else {
      e.preventDefault();
    }
  });
});