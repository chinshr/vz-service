App.Views.DocumentsPublishPopover = Backbone.View.extend({
  template: JST['documents/publish_popover'],

  initialize: function(options) {
    this.pages = {};
    this.parent = options.parent;
    _.bindAll(this, "render", "show", "hide", "toggle", "destroy", "remove",
      "publish", "rerender", "pushPage", "showPage", "showStartPage",
      "bindPage", "setup", "teardown");
  },

  render: function() {
    this.button = $('#publish-button');
    this.popover = this.button.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: 'bottom',
      template: '<div class="popover publish-popover" id="publish-popover"><div class="arrow"></div><div class="popover-content"></div></div>',
      content: this.$el.html(this.template(this.model.attributes))
    }).on('shown.bs.popover', this.setup)
      .on('hidden.bs.popover', this.teardown)
      .data("bs.popover");

    this.button.on('click', (function(_this) {
      return function(e) {
        _this.button.tooltip('hide');
        /* close all other popovers except this */
        _this.button.not(this).popover('hide');
        _this.popover.toggle();
      };
    })(this));

    $(document).on('click', (function(_this) {
      return function(e) {
        if (!$(e.target).is(_this.button) && $('#publish-popover').find($(e.target)).length === 0) {
          _this.hide();
        }
      }
    })(this));

    return this;
  },

  publish: function() {
    this.parent.publish();
  },

  rerender: function() {
    this.popover.setContent();
    this.popover.$tip.addClass(this.popover.options.placement);
  },

  pushPage: function(pid, object) {
    return this.pages[pid] = object;
  },

  showPage: function(pid) {
    var thisPage = this.pages[pid];
    if (thisPage) {
      thisPage.show();
      _.each(this.pages, function(v, k) {
        if (k !== pid) {
          v.hide();
        }
      });
      // this.rerender();
    }
  },

  showStartPage: function() {
    this.showPage('start');
  },

  bindPage: function(pid) {
    this.pushPage(pid, this.$('#' + pid));

    if (pid === 'privacy-page') {
      this.bindPrivacyPage(pid);
    }
  },

  bindPrivacyPage: function(pid) {
    var _this = this;

    var selectedRadio = function(reset) {
      if (reset) {
        return _this.$("input[type='radio'][value='" + _this.model.attributes.privacy + "']");
      } else {
        return $(_.select(_this.$("input[type='radio']"), function(radio) {
          return $(radio).is(':checked')
        }));
      }
    };

    var retrieveRadioData = function(radio, prefix) {
      var ae = $("#document-accessibility");
      var tag = ae.length > 0 ? (prefix + '-can-' + $("#document-accessibility").val()) : prefix;
      var text = radio.data(tag);
      if (typeof(text) === 'undefined') {
        text = radio.data(prefix);
      }
      return text;
    }

    var privacyTitle = function(reset) {
      return retrieveRadioData(selectedRadio(reset), 'title');
    };

    var privacyDescription = function(radio) {
      return retrieveRadioData(radio || selectedRadio(), 'description');
    };

    var triggerSelectedRadio = function(reset) {
      selectedRadio(reset).prop('checked', true)
        .closest('.btn-group .btn')
        .trigger('click');
    };

    var triggerSelect = function(reset) {
      var ae = $("#document-accessibility");
      var val;
      if (reset) {
        if (typeof(_this.model.attributes.accessibility) === 'object') {
          val = _this.model.attributes.accessibility[0];
        } else {
          val = _this.model.attributes.accessibility;
        }
        if (typeof(val) !== 'undefined') {
          ae.val(val);
        }
      }
      ae.trigger('change');
    }

    $('.btn-privacy-selection').html(privacyTitle(true));
    // $('.privacy-help').html(privacyDescription());

    this.$("input[type='radio']").on('change', function(e) {
      var radio = $(e.currentTarget);
      //_this.model.set({privacy: radio.val()});
      if (radio.is(':checked')) {
        if (radio.val() === 'private') {
          $(".form-group-document-accessibility").hide();
        } else {
          $(".form-group-document-accessibility").show();
        }

        $(".privacy-help").html(privacyDescription(radio));
      }
    });

    $("#document-accessibility").on('change', function(e) {
      var select = $(e.currentTarget);
      $(".privacy-help").html(privacyDescription());
    });

    triggerSelectedRadio(true);

    this.$('form').on('submit', (function(_this) {
      return function(e) {
        var data = {},
          form = $(e.target);

        e.originalEvent.preventDefault();
        _.map(form.serializeArray(), function(n) {
          var key;
          key = n['name'].match(/\[(.+)\]/);
          if (!!key && _.isArray(key) && key.length > 1) {
            return data[key[1]] = n['value'];
          }
        });

        _this.$(":submit").button("loading");
        _this.model.set(data, {validate: true});
        if (_this.model.isValid()) {
          return _this.model.sync('update', _this.model, {
            success: (function(_this) {
              return function() {
                _this.$(":submit").button("reset");
                _this.showStartPage();
                _this.publishButtonElement.prop('disabled', _this.model.attributes.privacy.indexOf('private') >= 0);
                _this.$('.btn-privacy-selection').html(privacyTitle());
              };
            })(_this),
            error: (function(_this) {
              return function() {};
            })(_this)
          });
        }
      }
    })(this));

    $('.btn-cancel').on('click', (function(_this) {
      return function() {
        triggerSelectedRadio(true);
        triggerSelect(true);
        _this.showStartPage();
      }
    })(this));
  },

  setup: function() {
    this.pushPage('start', this.$('#publish-popover-publishing-page'));

    this.publishButtonElement = this.$('.btn-publish-document');
    this.publishButtonElement.prop('disabled', this.model.attributes.privacy.indexOf('private') >= 0);
    this.publishButtonElement.on('click', this.publish).on('click', function(e) {
      $(e.currentTarget).button("loading");
    });

    var _this = this;
    this.$('.privacy-options .btn-options').each(function(ix, btn) {
      var pid = $(btn).data('target');
      _this.bindPage(pid);
      $(btn).on('click', function(e) {
        _this.showPage(pid);
      });
    });
  },

  teardown: function() {
    this.$('.btn-publish-document').off('click');
    this.$('.privacy-options .btn-options').each(function(ix, btn) {
      $(btn).off('click');
    });
    this.showStartPage();
    this.pages = {};
  },

  show: function() {
    this.button.popover("show");
  },

  hide: function() {
    this.button.popover("hide");
  },

  toggle: function() {
    this.button.popover("toggle");
  },

  destroy: function() {
    this.button.popover("destroy");
    this.button.remove();
    this.button = null;
  },

  remove: function() {
    this.destroy();
  }
});
