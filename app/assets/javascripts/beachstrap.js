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
//= require lib/bootstrap
//= require lib/rails.validations
//= require lib/rails.validations.bootstrap
//= require lib/detect_timezone
//= require lib/beachstrap/waypoints.min.js
//= require lib/beachstrap/beachstrap-script
//= require lib/beachstrap/jquery.nav
//= require lib/beachstrap/jquery.scrollTo
//= require lib/beachstrap/holder
//= require lib/beachstrap/bootstrap.youtubepopup
//= require web/common

/*
VZ._registration = (function() {
  var interval;

  var stop = function stop() {
    return window.clearInterval(interval);
  };

  var trigger = function trigger() {
    $('input#registration_email').trigger('blur');
    $('input#registration_email').trigger('focus');
  };

  var fail = function fail(element, message, callback) {
    callback();
    stop();
  }

  var pass = function pass(element, callback) {
    stop();
    callback();
    interval = setInterval(submit, 500);
  }

  var submit = function submit() {
    stop();
    $('input#registration_email').submit();
  }

  $(function() {
    ClientSideValidations.callbacks.element.fail = fail;
    ClientSideValidations.callbacks.element.pass = pass;

    $('.registration-form input#registration_email').bind('keyup', function(event) {
      stop();
      if (event.keyCode != 13) {
        interval = setInterval(trigger, 5000);
      }
    });
  });
})();
*/

$(function() {
  $(".youtube").YouTubeModal({autoplay:1, width:680, height:380, color: "#151a28", controls: 0, theme: "dark", 
    title: "Stanford Knight Talk: Ana María Carrano"});

  $('body.pages').on('activate.bs.scrollspy', function(event) {
    if (event.target && event.target.id) {
      var body = $('body');
      if (body && body[0] && body[0].className.length > 0) {
        body[0].className = body[0].className.replace(/selected-(.*)-item/g, '');
        body[0].className = $.trim(body[0].className);
      }
      $('body').addClass(event.target.id);
    }
  });

  if ($(window).scrollTop() > 150) {
    $('body').addClass('load-header-contrast');
  }

  $(window).scroll(function() {
    $('body').removeClass('load-header-contrast');
    if ($(window).scrollTop() > 150) {
      $('body').removeClass('selected-main-item');
    } else if ($(window).scrollTop() <= 150) {
      $('body').addClass('selected-main-item');
    }
  });
});
