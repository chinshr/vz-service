/* Popovers */
$(document).ready(function() {

  $(".btn-popover, .button-popover").each(function (index, btn) {
    var target;
    if (target = $(btn).data('target')) {
      target = $('#' + $(btn).data('target'));
      var poId = $(btn).data('popover-id');
      var poClass = $(btn).data('popover-class');

      $(btn).popover({
        container: 'body',
        html : true,
        trigger: 'manual',
        placement: 'bottom',
        template: '<div class="popover ' + poClass + '" id="' + poId + '"><div class="arrow"></div><div class="popover-content"></div></div>',
        content: function() {
          return target.html();
        }
      }).on('shown.bs.popover', function() {
        $(btn).tooltip('disable');
      })
      .on('hidden.bs.popover', function() {
        $(btn).tooltip('enable');
      });

      $(btn).on('click', function(e) {
        $(btn).tooltip('hide');
        /* close all other popovers except this */
        $(btn).not(this).popover('hide');
        $(btn).popover('toggle');
      });

      $(document).on('click', function(e) {
        if (!$(e.target).is($(btn)) && $(btn).find($(e.target)).length === 0 && $('#' + poId).find($(e.target)).length === 0) {
          $(btn).popover('hide');
        }
      });

      // close on escape
      $(document).keydown((function(_this) {
        return function(e) {
          e.stopPropagation();
          if (e.keyCode === 27) {
            $(btn).popover('hide');
          }
        }
      })(this));

    }
  });

});
