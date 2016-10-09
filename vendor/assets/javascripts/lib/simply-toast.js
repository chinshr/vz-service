(function() {
  $.notify = function(message, type, options) {
    options = $.extend(true, {}, $.notify.defaultOptions, options);

    var html = '<div class="simply-toast alert alert-' + (type ? type : options.type) + ' ' + (options.customClass ? options.customClass : '') +'">';
      if(options.allowDismiss)
        html += '<span class="close" data-dismiss="alert">&times;</span>';
      html += message;
      html += '</div>';

    var offsetSum = options.offset.amount;
    $('.simply-toast').each(function()
    {
      return offsetSum = Math.max(offsetSum, parseInt($(this).css(options.offset.from)) + this.offsetHeight + options.spacing);
    });

    var css = {
      'position': (options.appendTo === 'body' ? 'fixed' : 'absolute'),
      'margin': 0,
      'z-index': '9999',
      'display': 'none',
      'min-width': options.minWidth,
      'max-width': options.maxWidth
    };

    css[options.offset.from] = offsetSum + 'px';

    var $alert = $(html).css(css)
      .appendTo(options.appendTo);

    switch (options.align) {
      case "center":
        $alert.css(
        {
          "left": "50%",
          "margin-left": "-" + ($alert.outerWidth() / 2) + "px"
        });
        break;
      case "left":
        $alert.css("left", "10px");
        break;
      default:
        $alert.css("right", "10px");
    }

    if($alert.fadeIn) $alert.fadeIn();
    else $alert.css({display: 'block', opacity: 1});

    function removeAlert() {
      $.notify.remove($alert);
    }

    if(options.delay > 0) {
      setTimeout(removeAlert, options.delay);
    }

    $alert.find("[data-dismiss=\"alert\"]").removeAttr('data-dismiss').click(removeAlert);

    return $alert;
  };

  $.notify.remove = function($alert) {
    if($alert.fadeOut)
    {
      return $alert.fadeOut(function()
      {
        return $alert.remove();
      });
    }
    else
    {
      return $alert.remove();
    }
  };

  $.notify.defaultOptions = {
    appendTo: "body",
    customClass: false,
    type: "info",
    offset:
    {
      from: "top",
      amount: 20
    },
    align: "right",
    minWidth: 250,
    maxWidth: 450,
    delay: 4000,
    allowDismiss: true,
    spacing: 10
  };
})();