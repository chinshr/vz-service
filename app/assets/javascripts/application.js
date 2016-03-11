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
//= require lib/pubnub
//= require lib/nprogress
//= require lib/sprintf
//= require lib/chosen.jquery
//= require lib/select2
//= require lib/bootstrap
//= require lib/rails.validations
//= require lib/rails.validations.bootstrap
//= require lib/detect_timezone
//= require lib/jquery.query
//= require lib/imagesloaded
//= require lib/isotope
//= require lib/jquery.iframe-transport
//= require lib/jquery.fileupload
//= require underscore
//= require backbone
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
//= require web/documents
//= require web/account/account_application
//= require app/app

$(document).ready(function(){
  $(window).load(function() {
    $(".browser-grid").isotope('reLayout');
  });
});
