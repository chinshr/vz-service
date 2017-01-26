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
