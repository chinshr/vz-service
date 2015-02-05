/* For email format client side validations */
ClientSideValidations.validators.local["email_format"] = function(element, options) {
  if (!/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.test(element.val())) {
    return options.message;
  }
}

ClientSideValidations.formBuilders['ActionView::Helpers::FormBuilder'] = {
  add: function(element, settings, message) {
    if (message && message.length >0) {
      message = message[0].toUpperCase() + message.slice(1);
    }

    if (element.data('error-style') === 'tooltip') {
      var position = element.data('tooltip-position') || 'right'
      element.tooltip({
        placement: position,
        trigger: 'manual',
        title: message
      });
      element.data("tooltip", "true")
      element.tooltip('show');
    } else if (element.data('error-style') === 'inline') {
      var errorElement, wrapper;

      settings.wrapperSelector     = ".form-group";
      settings.errorTag            = "p";
      settings.errorClass          = "help-block";
      settings.wrapperErrorClass   = "has-error";
      settings.wrapperSuccessClass = "has-success";

      if (element.data('valid') !== false) {
        wrapper = element.closest(settings.wrapperSelector);
        wrapper.removeClass(settings.wrapperSuccessClass);
        wrapper.addClass(settings.wrapperErrorClass);
        errorElement = $("<" + settings.errorTag + "/>", {
          "class": settings.errorClass,
          text: message
        });
        return wrapper.append(errorElement);
      } else {
        wrapper = element.closest(settings.wrapperSelector);
        wrapper.addClass(settings.wrapperErrorClass);
        return element.parent().find("" + settings.errorTag + "." + settings.errorClass).text(message);
      }
    }
  },

  remove: function(element, settings) {
    if (element.data('error-style') === 'tooltip') {
      if (element.data('tooltip')) {
        element.tooltip('hide');
      }
    } else if (element.data('error-style') === 'inline') {
      var errorElement, wrapper;

      settings.wrapperSelector     = ".form-group";
      settings.errorTag            = "p";
      settings.errorClass          = "help-block";
      settings.wrapperErrorClass   = "has-error";
      settings.wrapperSuccessClass = "has-success";

      wrapper = element.closest("" + settings.wrapperSelector + "." + settings.wrapperErrorClass);
      wrapper.removeClass(settings.wrapperErrorClass);
      wrapper.addClass(settings.wrapperSuccessClass);
      errorElement = wrapper.find("" + settings.errorTag + "." + settings.errorClass);
      return errorElement.remove();
    }
  }
};