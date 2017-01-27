/* SlideMenu */

(function() {
  function SlideMenu(opts) {
    if (!opts) opts = {};
    this.toggler = opts.toggler || '.navbar-toggle';
    this.pagewrapper = opts.pagewrapper || '#content';
    this.navigationWrapper = opts.navigationWrapper || '.navbar-header';
    this.menuWidth = opts.menuWidth || '100%'; // the menu inside the slide menu itself
    this.menuNeg = opts.menuNeg || '-100%';
    this.slideWidth = opts.slideWidth || '80%';
    this.slideNeg = opts.slideNeg || '-80%';
  }

  SlideMenu.load = function(opts) {
    var slideMenu;
    if ($('.navbar-toggle').length > 0) {
      slideMenu = new SlideMenu(opts);
      slideMenu.start();
    }
    return slideMenu;
  };

  SlideMenu.prototype.start = function() {
    var _this = this;

    $('header.page-header .container').append($('<div id="navbar-height-col"></div>'));

    $("header.page-header").on("click", _this.toggler, function(e) {
      var selected = $(this).hasClass('slide-active');

      $('#slidemenu').stop().animate({
        right: selected ? _this.menuNeg : '0px'
      });

      $('#navbar-height-col').stop().animate({
        right: selected ? _this.slideNeg : '0px'
      });

      $(_this.pagewrapper).stop().animate({
        right: selected ? '0px' : _this.slideWidth
      });

      $(_this.navigationWrapper).stop().animate({
        right: selected ? '0px' : _this.slideWidth
      });

      $(this).toggleClass('slide-active', !selected);
      $('#slidemenu').toggleClass('slide-active');

      $('#content, header.page-header, body, .navbar-header').toggleClass('slide-active');
    });

    var selected = '#slidemenu, #content, body, .navbar, .navbar-header';

    $(window).on("resize", function () {
      if ($(window).width() > 767 && $('.navbar-toggle').is(':hidden')) {
        $(selected).removeClass('slide-active');
      }
    });
  }

  window.SlideMenu = SlideMenu;
})();
