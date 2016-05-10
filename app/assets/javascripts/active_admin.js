//= require active_admin/base
//= require underscore
//= require gmaps/google
//= require chartkick

$(function() {
  $('.member_link[confirm]').on('click', function(e) {
    if (confirm($(this).attr('confirm'))) {
      // execute!
    } else {
      e.preventDefault();
    }
  });
});