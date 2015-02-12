//= require active_admin/base
//= require highcharts
//= require underscore
//= require gmaps/google

$(function() {
  $('.member_link[confirm]').on('click', function(e) {
    if (confirm($(this).attr('confirm'))) {
      // execute!
    } else {
      e.preventDefault();
    }
  });
});