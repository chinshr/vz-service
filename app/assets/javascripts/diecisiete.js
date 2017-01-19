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
//= require helpers/common

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

$(function() {
  var gallery = new Gallery({
    interval: 1400,
    interval: 3800,
    slides: 3
  });
  gallery.start();

  var siriWave = new SiriWave({
    container: document.getElementById('siri-wave'),
    style: "ios9",
    cover: true,
    speed: 0.01,
    frequency: 0.2,
    amplitude: 0.7,
    definition: [
      { color: '84,130,140' },
      { color: '118,183,198' },
      { color: '153,237,255' }
    ]
  });
  siriWave.start();
});
