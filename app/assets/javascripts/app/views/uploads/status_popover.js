App.Views.UploadsStatusPopover = App.Views.PopoverBase.extend({
  template: JST['uploads/status_popover'],

  events: {
    'click .action' : 'trigger'
  },

  initialize: function(options) {
    App.Views.PopoverBase.prototype.initialize.call(this, options); // super
    _.bindAll(this, "setup", "teardown", "trigger");
  },

  render: function() {
    this.holder  = this.parent.$(".upload-status");
    this.popover = this.holder.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: this.placement,
      template: '<div class="popover status-popover" id="status-popover"><div class="arrow"></div><div class="popover-content"></div></div>',
      content: this.$el.html(this.template(_.extend({
      }, this.model.attributes)))
    }).on('shown.bs.popover', this.setup)
      .on('hidden.bs.popover', this.teardown)
      .data("bs.popover");

    // close popover when another one is opened
    this.holder.on('click', (function(_this) {
      return function(e) {
        e.stopPropagation();
        e.preventDefault();
        if (e.shiftKey) {
          _this.holder.tooltip('hide');
          // close all other popovers except this
          _this.holder.not(this).popover('hide');
          $('.upload-status, .btn-popover, [data-rel="popover"], .popover').not(_this.holder).popover('hide');
          _this.popover.toggle();
        }
      };
    })(this));

    // ???
    $(document).on('click', (function(_this) {
      return function(e) {
        if (!$(e.target).is(_this.holder) && _this.holder.find($(e.target)).length === 0 && $(".btn-more").find($(e.target)).length === 0) {
          _this.hide();
        }
      }
    })(this));

    // close on escape
    $(document).keydown((function(_this) {
      return function(e) {
        e.stopPropagation();
        if (e.keyCode === 27) {
          _this.hide();
        }
      }
    })(this));

    this.holder.show();
    return this;
  },

  setup: function() {
    this.holder.tooltip('disable');
  },

  teardown: function() {
    this.holder.tooltip('enable');
  },

  trigger: function(event) {
    event.preventDefault();
    this.hide();
    this.parent.trigger(this, event);
  },

  update: function() {
    // .action-start
    if (this.parent.model.attributes._events.indexOf('start') !== -1) {
      this.$('.action-start').parent().removeClass('disabled');
    } else {
      this.$('.action-start').parent().addClass('disabled');
    }

    // .action-stop
    if (this.parent.model.attributes._events.indexOf('stop') !== -1) {
      this.$('.action-stop').parent().removeClass('disabled');
    } else {
      this.$('.action-stop').parent().addClass('disabled');
    }

    // .action-reset
    if (this.parent.model.attributes._events.indexOf('reset') !== -1) {
      this.$('.action-reset').parent().removeClass('disabled');
    } else {
      this.$('.action-reset').parent().addClass('disabled');
    }
  }
});
