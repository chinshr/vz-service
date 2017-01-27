/* Gallery */

(function() {
  function Gallery(opts) {
    if (!opts) opts = {}
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

  Gallery.load = function(opts) {
    var gallery = new Gallery(opts);
    gallery.start();
    return gallery;
  };

  Gallery.prototype.bind = function() {
    var _this = this;
    $(_this.selector).on("click", ".item, .dot-off", function() {
      _this.didUserStartedManually = true;
      _this.stop();
      _this.changeSlide($(this));
    });
  };

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
  };

  Gallery.prototype.stop = function() {
    clearTimeout(this.homeGalleryTimeout);
    clearInterval(this.homeGalleryInterval);
  };

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
  };

  window.Gallery = Gallery;
})();
