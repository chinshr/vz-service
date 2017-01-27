(function() {
  ScrollTop = function(opts) {
    if (!opts) opts = {};
    this.top = opts.top || 200;
    this.interval = opts.interval || 250;
    this.callback = opts.callback || false;

    this.didHit = false;
    this.scrollInterval = false;
  };

  ScrollTop.prototype.bind = function() {
    var _this = this;

    if (window.pageYOffset && window.pageYOffset >= _this.top) {
      // we already over the top position
      _this.callback(_this);
    } else {
      // othewise, have scroll event
      $(window).scroll(function(event) {
        if ($(window).scrollTop() >= _this.top) {
          _this.didHit = true;
        }
      });

      _this.scrollInterval = setInterval(function() {
        if (_this.didHit) {
          clearInterval(_this.scrollInterval);
          _this.callback(_this);
        }
      }, _this.interval);
    }
  };

  ScrollTop.load = function(opts, callback) {
    var scrollTop = new ScrollTop(opts);
    scrollTop.callback = callback;
    scrollTop.bind();
    return scrollTop;
  };

  window.ScrollTop = ScrollTop;
})();
