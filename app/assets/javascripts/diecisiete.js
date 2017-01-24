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
//= require helpers/common

/* Gallery */
(function() {
  function Gallery(opts) {
    this.selector = opts.selector || "#gallery";
    this.delay = opts.delay || 1400;
    this.interval = opts.interval || 3000;
    this.slides = opts.slides || 3;

    this.didCarouselStart = false;
    this.didUserStartedManually = false;
    this.currentSlide = 1;
    this.homeGalleryTimeout = false;
    this.homeGalleryInterval = false;

    this.bind();
  }

  Gallery.prototype.bind = function() {
    var _this = this;
    $(_this.selector).on("click", ".item, .dot-off", function() {
      _this.didUserStartedManually = true;
      _this.stop();
      _this.changeSlide($(this));
    });
  }

  Gallery.prototype.start = function() {
    var _this = this;
    this.didCarouselStart = true;

    _this.homeGalleryTimeout = setTimeout(function() {
      _this.changeSlide(2);
      _this.homeGalleryInterval = setInterval(function() {
        var nextAutomaticSlide;
        if (_this.currentSlide < $(_this.selector + " .slide").length) {
          nextAutomaticSlide = _this.currentSlide + 1;
        } else {
          nextAutomaticSlide = 1;
        }
        _this.changeSlide(nextAutomaticSlide);
      }, _this.interval);
    }, _this.delay);
  }

  Gallery.prototype.stop = function() {
    clearTimeout(this.homeGalleryTimeout);
    clearInterval(this.homeGalleryInterval);
  }

  Gallery.prototype.changeSlide = function(clickedObject) {
    var _this = this,
      newSlideNumber,
      selectorNewPosition;
    if ($(clickedObject).attr("class") == "item" || $(clickedObject).attr("class") == "dot-off") {
      newSlideNumber = $(clickedObject).attr("id").slice(-1);
    } else {
      newSlideNumber = clickedObject;
    }

    $("#home-gallery-item-" + _this.currentSlide).attr("class", "item");
    $("#home-gallery-item-" + newSlideNumber).attr("class", "item-selected");
    $("#home-gallery-dot-" + _this.currentSlide).attr("class", "dot-off");
    $("#home-gallery-dot-" + newSlideNumber).attr("class", "dot-on");

    selectorNewPosition = 33.3 * (newSlideNumber - 1) + "%";
    $(_this.selector + " .selector").animate({"left": selectorNewPosition}, 400, "easeOutCubic");

    $("#slide-" + _this.currentSlide).fadeOut(200, function() {
      $("#slide-" + _this.currentSlide).removeClass("slide-selected");
      $("#slide-" + _this.currentSlide).hide();
      $("#slide-" + newSlideNumber + " h2").hide();
      $("#slide-" + newSlideNumber + " p").hide();
      $("#slide-" + newSlideNumber).addClass("slide-selected");
      $("#slide-" + newSlideNumber).show();
      $("#slide-" + newSlideNumber + " img").css({"top":30, "opacity":0});
      $("#slide-" + newSlideNumber + " img").delay(200).animate({"top":0, "opacity":1}, 350, "easeOutCubic");
      $("#slide-" + newSlideNumber + " h2").delay(200).fadeIn(350, "easeOutCubic");
      $("#slide-" + newSlideNumber + " p").delay(200).fadeIn(350, "easeOutCubic");
    });
    this.currentSlide = newSlideNumber
  }

  window.Gallery = Gallery;
})();

/* ScrollHeader */
(function() {
  function ScrollHeader(opts) {
    this.didScroll = false;
    this.lastScrollTop = 0;
    this.delta = opts.delta || 5;
    this.interval = opts.interval || 250;
    this.headerEl = $('header');
    this.navbarHeight = this.headerEl.outerHeight();
    this.scrollInterval = false;
  }

  ScrollHeader.prototype.start = function() {
    var _this = this;

    $(window).scroll(function(event) {
      _this.didScroll = true;
    });

    _this.scrollInterval = setInterval(function() {
      if (_this.didScroll) {
        _this.hasScrolled();
        _this.didScroll = false;
      }
    }, _this.interval);
  }

  ScrollHeader.prototype.hasScrolled = function() {
    var st = $(window).scrollTop();

    // make sure they scroll more than delta
    if (Math.abs(this.lastScrollTop - st) <= this.delta) {
      return;
    }

    // if they scrolled down and are past the navbar, add class .nav-up.
    // This is necessary so you never see what is "behind" the navbar.
    if (st > this.lastScrollTop && st > this.navbarHeight) {
      // scroll Down
      this.headerEl.removeClass('nav-down').addClass('nav-up');
    } else {
      // Scroll Up
      if(st + $(window).height() < $(document).height()) {
        this.headerEl.removeClass('nav-up').addClass('nav-down');
      }
    }

    this.lastScrollTop = st;
  }

  window.ScrollHeader = ScrollHeader;
})();

$(function() {
  // scroll header
  var scrollHeader = new ScrollHeader({});
  scrollHeader.start();

  // gallery
  var gallery = new Gallery({
    interval: 1400,
    interval: 3800,
    slides: 3
  });
  gallery.start();

  // siriwave
  var siriWave = new SiriWave({
    container: document.getElementById('siri-wave'),
    style: "ios9",
    cover: true,
    speed: 0.02,
    frequency: 10,
    amplitude: 0.7,
    definition: [
      { color: '84,130,140' },
      { color: '118,183,198' },
      { color: '153,237,255' }
    ]
  });
  siriWave.start();

  // typed
  $("#typed").typed({
    //strings: ["Your conversations <br/>deserve a place to be found", "Your conversations <br/>are safe with us"],
    stringsElement: $('#typed-strings'),
    cursorChar: "|",
    typeSpeed: 25,
    backSpeed: 10,
    backDelay: 1000,
    startDelay: 200,
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
  var $window = $(window)
  $window.scroll(function() {
    var yPos = -($window.scrollTop() / $('#parallax').data('speed') - 180);
    var coords = '50%' + yPos + 'px';
    $('#parallax').css({
      backgroundPosition: coords
    });
  });

  // form
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

});
