App.Views.UploadsSourceModal = Backbone.View.extend({
  template: JST['uploads/source_modal'],

  events: {
    'submit' : 'submit',
    'focusout input': 'inputChange'
  },

  initialize: function(options) {
    _.bindAll(this, "submit", "inputChange", "show", "hide", "destroy");

    this.parent    = options.parent;
    this.model     = new App.Models.Upload({
      locale: this.$("#file-locale").val() || "en-US",
      type: "media_upload"
    });
    this.callbacks = options.callbacks || {};

    Backbone.Validation.bind(this, {
      // labelFormatter: 'labels'
    });
  },

  render: function(params) {
    var template = this.template(_.extend(params || {}));
    this.setElement(template);
    $('body').append(this.$el);
    this.holder = $('#upload-source-modal');
    this.holder.on('hidden.bs.modal', this.destroy);
    return this;
  },

  submit: function(event) {
    var data, form;

    // console.log("=> submit", event);

    event.originalEvent.preventDefault();
    form = $(event.target);
    data = {};
    _.map(form.serializeArray(), function(n) {
      var key;
      key = n['name'].match(/\[(.+)\]/);
      if (!!key && _.isArray(key) && key.length > 1) {
        return data[key[1]] = n['value'];
      }
    });

    this.model.set(data, { validate: true });
    if (this.model.isValid()) {
      this.$('button[type="submit"]').button("loading");
      return this.model.sync('create', this.model, {
        success: (function(_this) {
          return function(data) {
            _this.$(":submit").button("reset");
            _this.model.set(_this.model.parse(data));
            _this.hide();
            if (_this.callbacks.success) {
              _this.callbacks.success(data);
            }
            _.defer(function() {
              _this.parent.collection.add(_this.model);
            });
            return _this;
          };
        })(this),
        error: (function(_this) {
          return function(response, xhr, options) {
            // var errors = JSON.parse(response.responseText)['errors'];
            var errors = (response.responseJSON || {}).errors || [];

            _this.$(":submit").button("reset");
            // console.log("=> response", response)

            _.each(errors, function(error, attr) {
              var label = Backbone.Validation.labelFormatters.label(attr, _this.model);
              error = _.map(error, function(val) {
                return [label, val].join(" ");
              });
              Backbone.Validation.callbacks.invalid(_this, attr, error, 'name');
            });
            _this.model.trigger('validated', false, _this.model, errors);
            _this.model.trigger('validated:invalid', self.model, errors);
            if (_this.callbacks.error) {
              _this.callbacks.error(response);
            }
            return _this;
          };
        })(this)
      });
    }
  },

  inputChange: function(event) {
    var data, field, key;
    field = $(event.currentTarget);
    data  = {};
    if (!!field.attr('name') && (key = field.attr('name').match(/\[(.+)\]/)[1])) {
      data[key] = field.val();
      this.model.set(data, {validate: true});
      return this.model.isValid();
    }
  },

  show: function() {
    if (this.$el.length !== 0) {
      this.holder.modal('show');
    }
    return this;
  },

  hide: function() {
    if (this.$el.length !== 0) {
      this.holder.modal('hide');
    }
    return this;
  },

  destroy: function() {
    // this.hide();
    // this.remove();
    // this.unbind();
    // return this;

    this.holder.popover("hide");
    this.holder.popover("destroy");
    // this.holder.remove();
    // this.holder = null;

    this.undelegateEvents();
    this.$el.removeData().unbind();
    Backbone.View.prototype.remove.call(this);

    delete this;
  }

});
