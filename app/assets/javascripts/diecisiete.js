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
//= require lib/siriwave
//= require lib/jquery.easing
//= require lib/bootstrap.youtubepopup
//= require lib/typed
//= require lib/particles
//= require helpers/common
//= require helpers/enhance_image
//= require helpers/slide_menu
//= require helpers/gallery
//= require helpers/scroll_header
//= require helpers/scroll_top

$(function() {
  // enhance images
  var mainImage = new EnhanceImage({
    imgClass: ".background-image",
    imgEnhancedClass: ".enhanced-image"
  }).bind();

  // scroll header
  var scrollHeader = new ScrollHeader({});
  scrollHeader.start();

  // slide menu
  SlideMenu.load({
    menuWidth: "245px",
    menuNeg: "-245px",
    slideWidth: "245px",
    slideNeg: "-245px"
  });

  // siriwave
  var siriWave = new SiriWave({
    container: document.getElementById('siri-wave'),
    style: "ios9",
    cover: true,
    speed: 0.02,
    frequency: 10,
    amplitude: 0.7,
    definition: [
      {color: '84,130,140'},
      {color: '118,183,198'},
      {color: '153,237,255'}
    ]
  });
  siriWave.start();

  // gallery
  ScrollTop.load({top: 200}, function() {
    Gallery.load({
      slides: 3,
      interval: 3800
    });
  });

  // typed
  $("#typed").typed({
    //strings: ["Your conversations <br/>deserve a place to be found", "Your conversations <br/>are safe with us"],
    stringsElement: $('#typed-strings'),
    cursorChar: "|",
    typeSpeed: 0,
    backSpeed: 0,
    backDelay: 3500,
    startDelay: 6000,
    loop: true
  });

  // video
  $(".youtube").YouTubeModal({
    autoplay:1,
    width:680,
    height:380,
    color: "#151a28",
    controls: 0,
    theme: "dark",
    title: "VOYZ.ES &mdash; Our Story",
    youtubeId: "_1ZoXYADBgw"
  });

  $('.youtube').bind('show.YouTubeModal', function() {
    VZ.trackEvent('home-page-play-video',
      {action: 'click-play-video', name: 'Our story'},
      function(event, data) {
        // console.log(event, data);
      }
    );
  });

  // parallax
  if (false && $('.parallax').length > 0) {
    var $window = $(window),
      $parallax = $('.parallax');
    $window.scroll(function() {
      var yPos = -($window.scrollTop() / ($parallax.data('speed') || 8) - 180);
      var coords = '50%' + yPos + 'px';
      $parallax.css({
        backgroundPosition: coords
      });
    });
  }

  // contact form
  $("#contact .button-contact-us").on('click', function() {
    $("#contact .form").show();
    $("#contact .button-contact-us").hide();
  });

  // cookie-law-bar
  if (!VZ.getCookie('cookie-law-accepted')) {
    $("body").append("<div id='cookie-law-bar'><div class='inner-wrapper'><p>We use cookies to ensure that we give you the best experience on our website. If you continue to use this site we will assume that you are fine with it.</p><div class='button button-with-chrome button-cookie-law-bar'>OK</div><div style='clear:both;'</div></div></div>");

    $("#cookie-law-bar .button-cookie-law-bar").on('click', function() {
      VZ.setCookie('cookie-law-accepted', 'true', 365);
      $("#cookie-law-bar").hide();
    });
  }

  // particles
  ScrollTop.load({top: 500}, function() {
    particlesJS.load('particles', 'assets/config/benefits-particles.json', function() {
    });
  });

});
