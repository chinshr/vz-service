// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui/core
//= require jquery-ui/widget
//= require jquery-ui/datepicker
//= require lib/pubnub
//= require lib/nprogress
//= require lib/sprintf
//= require lib/chosen.jquery
//= require lib/select2
//= require lib/bootstrap
//= require lib/rails.validations
//= require lib/rails.validations.bootstrap
//= require lib/rails.validations.custom_validators
//= require lib/detect_timezone
//= require lib/jquery.query
//= require lib/imagesloaded
//= require lib/isotope
//= require lib/jquery.iframe-transport
//= require lib/jquery.fileupload
//= require lib/jquery.creditCardValidator
//= require lib/vanillaTextMask
//= require lib/intro
//= require underscore
//= require backbone
//= require payola
//= require lib/backbone/backbone.validation
//= require lib/backbone/backbone.validation.config
//= require lib/simply-toast
//= require lib/s3upload
//= require lib/bootstrap-colorpicker
//= require lib/bootstrap-slider.min
//= require helpers/common
//= require helpers/social
//= require helpers/i18n
//= require helpers/alert
//= require helpers/confirm
//= require helpers/popover
//= require helpers/slide_menu
//= require web/documents
//= require web/account/account_application
//= require app/app

$.ajaxPrefilter(function(options, originalOptions, xhr) {
  var token = $('meta[name="csrf-token"]').attr('content');
  xhr.setRequestHeader('X-CSRF-Token', token);
});

// override the default confirm dialog behavior
$.rails.allowAction = function(link){
  if (link.data("confirm") == undefined){
    return true;
  }
  var message = link.data("confirm");

  $.confirm(message, function(result) {
    if (result) {
      link.data("confirm", null);
      link.trigger("click.rails");
    }
    return result;
  });

  return false;
}

$(function() {
  // slide menu
  if ($('.navbar-toggle').length > 0) {
    new SlideMenu({
      menuWidth: "245px",
      menuNeg: "-245px",
      slideWidth: "245px",
      slideNeg: "-245px"
    }).start();
  }
});
