App.Views.UploadsEdit = App.Views.UploadsBase.extend({
  template: JST['uploads/edit'],
  className: 'tile edit-tile col-lg-4 col-md-4 col-sm-4',

  events: _.extend({
    'click .action-close' : 'flipTile',
    'keyup input': 'onFieldChange',
    'change select': 'onSelectionChange',
    'submit' : 'onFormSubmit',
    'change .btn-group .btn input[type=radio]:radio' : (function(event) {
      var radio = $(event.currentTarget);
      this.model.set({privacy: radio.val()});
      console.log("=> radio triggered");
      if (!radio.data('triggered')) {
        console.log("=> radio changed + .btn triggered");
        // radio.closest('.btn-group .btn').trigger('click');
      }
    }),
  }, App.Views.UploadsBase.prototype.events),

  initialize: function() {
    App.Views.UploadsBase.prototype.initialize.call(this); // super
    Backbone.Validation.bind(this);
    this.listenTo(this.model, 'change:privacy', this.renderUpdate);
  },

  render: function(attributes) {
    // super
    App.Views.UploadsBase.prototype.render.call(this, attributes);

    _.defer((function(_this) {
      return function() {
        // tags
        _this.$('.input-taggable').select2({
          minimumInputLength: 3,
          multiple: true,
          maximumInputLength: 15,
          tokenSeparators: [",", " ", ".", "|"],
          ajax: {
            url: window.location.protocol + "//" + window.location.host + "/api/tags.json",
            dataType: 'json',
            type: 'GET',
            quietMillis: 100,
            data: function (term, page) { // page is the one-based page number tracked by Select2
              return {
                named_like: term, // search term
                most_used: 10, // page size
                offset: (page - 1) * 10 // page number
              };
            },
            results: function (data, page) {
              var results = [];
              $.each(data.tags, function(index, item){
                results.push({
                  text: item.name,
                  id: item.name  // item.id,
                });
              });
              return {results: results, more: false};
            }
          },
          initSelection: function(el, callback) {
            var data = [];
            $(el.val().split(',')).each(function() {
              data.push({id: this, text: this});
            });
            callback(data);
          },
          createSearchChoice: function (term, data) {
            if ($(data).filter( function() {
              return this.text.localeCompare(term) === 0;
            }).length === 0) {
              return {id:term, text:term};
            }
          }
        });
      }
    })(this));

    return this;
  },

  flipTile: function() {
    var edit     = this;
    var editHTML = edit.$el;
    var show     = new App.Views.UploadsShow({model: this.model});
    var showHTML = show.render(this.model.attributes).$el;

    if (Modernizr.csstransforms3d) {
      showHTML.find('.panel').css({
        'transform': 'rotateY(180deg)',
        '-webkit-transform': 'rotateY(180deg)',
        'position': 'absolute',
        'top': '0',
        'left': '0',
        'width': '100%'
      }).appendTo(editHTML.find('.flipper'));

      editHTML.addClass('flip');
      editHTML.bind('transitionend -moz-transitionend -webkit-transitionend -o-transitionend', (function(_this) {
        return function(e) {
          _this.$el.replaceWith(show.render(_this.model.attributes).el);
          edit.remove();
          console.log("=> transition ended");
        };
      })(this));
    } else {
      this.$el.replaceWith(show.render(this.model.attributes).el);
      edit.remove();
    }
  },

  renderUpdate: function(hasProgress) {
    App.Views.UploadsBase.prototype.renderUpdate.call(this, hasProgress); // super

    this.$("input[name='upload[title]']").val(this.model.attributes.title);
    this.$("input[name='upload[tag_list]']").val(this.model.attributes.tag_list);
    this.$("textarea[name='upload[description]']").val(this.model.attributes.description);
    this.$("select[name='upload[locale]']").val(this.model.attributes.locale);
    this.$("form, form input, form textarea, form button").removeAttr('disabled');
    this.$(".form-fields").show();

    // privacy
    this.$("input[type='radio'][value='" + this.model.attributes.privacy + "']").
      prop('checked', true).
      closest('.btn-group .btn').trigger('click');
  },

  onFieldChange: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data  = {};
    if (!!field.attr('name') && (key = field.attr('name').match(/\[(.+)\]/)[1])) {
      data[key] = field.val();
      this.model.set(data, {validate: true});
      return this.model.isValid();
    }
  },

  onSelectionChange: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data = {};
    if (key = field.attr('name').match(/\[(.+)\]/)[1]) {
      data[key] = field.val();
      this.model.set(data, {validate: true});
      return this.model.isValid();
    }
  },

  onFormSubmit: function(e) {
    console.log("=> submit");

    var data, form;
    e.originalEvent.preventDefault();
    form = $(e.target);
    data = {};
    _.map(form.serializeArray(), function(n) {
      var key;
      key = n['name'].match(/\[(.+)\]/);
      if (!!key && _.isArray(key) && key.length > 1) {
        return data[key[1]] = n['value'];
      }
    });
    this.model.set(data, {validate: true});
    if (this.model.isValid()) {
      this.$(":submit").button("loading");
      return this.model.sync('update', this.model, {
        success: (function(_this) {
          return function() {
            _this.$(":submit").button("reset");
            return _this.flipTile();
          };
        })(this),
        error: (function(_this) {
          return function() {
            return _this.$(":submit").button("reset");
          };
        })(this)
      });
    }
  },
});