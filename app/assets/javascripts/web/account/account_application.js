$(function() {
  if (VZ.getCookie('vz-hide-dashboard-welcome', false)) {
    $('#welcome-container').hide();
  } else {
    $('#welcome-container').show();
  }

  $('#welcome-container .close').on('click', function() {
    VZ.setCookie('vz-hide-dashboard-welcome', true)
  });

  $('.input-single-searchable').chosen({});

  $("#user_username").on('keyup', function(event) {
    $(event.target).parent().find(".help-block i").html(window.location.origin + "/@" + $(event.target).val());
  });
});
