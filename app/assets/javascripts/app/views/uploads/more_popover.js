App.Views.UploadsMorePopover = App.Views.PopoverBase.extend({
  template: JST['uploads/more_popover'],

  events: {
    'click .action' : 'trigger'
  },

  initialize: function(options) {
    App.Views.PopoverBase.prototype.initialize.call(this, options); // super
    _.bindAll(this, "setup", "teardown", "trigger");
  },

  render: function() {
    this.holder  = this.parent.$(".btn-more");
    this.popover = this.holder.popover({
      container: 'body',
      html : true,
      trigger: 'manual',
      placement: this.placement,
      template: '<div class="popover more-popover" id="more-popover"><div class="arrow"></div><div class="popover-content"></div></div>',
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
        _this.holder.tooltip('hide');
        /* close all other popovers except this */
        _this.holder.not(this).popover('hide');
        $('.btn-more, .btn-popover, [data-rel="popover"], .popover').not(_this.holder).popover('hide');
        _this.popover.toggle();
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
    this.hide();
    this.parent.trigger(this, event);
  },

  update: function() {
    // .edit-action
    if (this.parent.model.hasFinished()) {
      this.$('a.edit-slug').attr('href', this.parent.model.editURL());
      this.$('.action-edit').parent().removeClass('disabled');
    } else {
      this.$('.action-edit').parent().addClass('disabled');
    }

    // .preview-action
    if (this.parent.model.hasFinished()) {
      this.$('a.preview-slug').attr('href', this.parent.model.previewURL());
      this.$('.action-preview').parent().removeClass('disabled');
    } else {
      this.$('.action-preview').parent().addClass('disabled');
    }

    // .published-action
    if (!!this.parent.model.publishedURL()) {
      this.$('a.published-slug').attr('href', this.parent.model.publishedURL());
      this.$('.action-published').parent().removeClass('disabled');
    } else {
      this.$('.action-published').parent().addClass('disabled');
    }
  }
});