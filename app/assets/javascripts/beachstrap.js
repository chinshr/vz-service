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
//= require jquery.ui.core
//= require jquery.ui.widget
//= require bootstrap
//= require beachstrap/waypoints.min.js
//= require beachstrap/beachstrap-script
//= require beachstrap/jquery.nav
//= require beachstrap/jquery.scrollTo
//= require beachstrap/holder
//= require beachstrap/bootstrap.youtubepopup

$(function() {

  $(".youtube").YouTubeModal({autoplay:1, width:680, height:380, color: "#151a28", controls: 0, theme: "dark", 
    title: "Stanford Knight Talk: Ana María Carrano"});

  $('body').on('activate.bs.scrollspy', function (event) {
    if (event.target && event.target.id) {
      var body = $('body');
      if (body && body[0] && body[0].className.length > 0) {
        body[0].className = body[0].className.replace(/selected-(.*)-item/g, '');
        body[0].className = $.trim(body[0].className);
      }
      $('body').addClass(event.target.id);
    }
  })
});
