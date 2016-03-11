App.Views.TilesEdit = App.Views.TilesBase.extend({
  template: JST['tiles/edit'],
  className: 'tile edit-tile col-lg-4 col-md-4 col-sm-4',

  events: _.extend({
    'focusout input': 'onFieldChange',
    'change select': 'onSelectionChange',
    'submit': 'onFormSubmit',
  }, App.Views.TilesBase.prototype.events),

  initialize: function(options) {
    _.bindAll(this, "selectImage", "dropImage", "imageUploadFinished", "imageUploadStopped", "imageUploadCanceled", "flipTile");
    App.Views.TilesBase.prototype.initialize.call(this, options); // super
    Backbone.Validation.bind(this);
    this.listenTo(this.model, 'change:privacy', this.update);
  },

  render: function(attributes) {
    App.Views.TilesBase.prototype.render.call(this, attributes); // super

    _.defer((function(_this) {
      return function() {
        _this.initImageUploadInput();
        _this.$(".action-close").on("click", _this.flipTile);
        _this.initTagEditor();
      }
    })(this));

    return this;
  },

  flipTile: function(event) {
    var edit   = this,
      editHTML = edit.$el,
      show     = new (this.showTileClass())({model: this.model, parent: this.parent}).render(),
      showHTML = show.template(show.model.attributes);

    if (event) {
      event.stopPropagation();
      event.originalEvent.preventDefault();
    }
    if (Modernizr.csstransforms3d) {
      $(showHTML).find('.panel').css({
        'transform': 'rotateY(180deg)',
        '-webkit-transform': 'rotateY(180deg)',
        'position': 'absolute',
        'top': '0',
        'left': '0',
        'width': '100%'
      }).appendTo(editHTML.find('.flipper'));
      editHTML.bind('transitionend -moz-transitionend -webkit-transitionend -o-transitionend', function(e) {
        edit.$el.parent().append(show.$el);
        edit.remove();
        if (show.parent) {
          show.parent.refreshLayout();
        }
      });
      editHTML.addClass('flip');
    } else {
      edit.$el.parent().append(show.$el);
      edit.remove();
    }
  },

  update: function(hasProgress) {
    App.Views.TilesBase.prototype.update.call(this, hasProgress); // super

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

    this.model.set(data, { validate: true });
    if (this.model.isValid()) {
      this.$('button[type="submit"]').button("loading");

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

  initImageUploadInput: function() {
    var _this = this,
      input = this.$('input:file').detach();
    this.$('.thumb-upload.image').each(function () {
      input.on('click', function(e) {
        e.stopPropagation();
      }).on('change', _this.selectImage);

      $(this)
        .append(input)
        .on('click', function(e) {
          e.stopPropagation();
          e.preventDefault();
          input.click();
        });
    });
  },

  selectImage: function(event) {
    if ($(event.target).val() !== '') {
      this.imageUpload = new App.Views.PopoversImageUpload({
        parent: this,
        holder: this.$('.thumb-upload.image'),
        selector: this.$('.image-upload'),
        dropped: false,
        placement: "bottom",
        callbacks: {
          finished: this.imageUploadFinished,
          stopped: this.imageUploadStopped,
          canceled: this.imageUploadCanceled,
        }
      }).render().show();
    }
  },

  dropImage: function(event) {
    event.originalEvent.preventDefault();
    if (event.originalEvent.dataTransfer !== null) {
      this.imageUpload = new App.Views.PopoversImageUpload({
        parent: this,
        holder: this.$('.thumb-upload.image'),
        files: event.originalEvent.dataTransfer.files,
        dropped: true,
        callbacks: {
          finished: this.imageUploadFinished,
          stopped: this.imageUploadStopped,
          canceled: this.imageUploadCanceled,
        }
      }).render().show();
    }
  },

  imageUploadFinished: function(model) {
    var _this = this;
    this.model.fetch({
      success: function() {
        _this.updateImages();
        _this.imageUpload.destroy();
        _this.initImageUploadInput();
      },
      error: function() {
        _this.imageUpload.destroy();
        _this.initImageUploadInput();
      }
    });
  },

  imageUploadStopped: function(model) {
    this.imageUpload.destroy();
    this.initImageUploadInput();
  },

  imageUploadCanceled: function() {
    this.imageUpload.destroy();
    this.initImageUploadInput();
  },

  updateImages: function(data) {
    var squareImageSrc = this.model.imageSource(1);
    if (!!squareImageSrc) {
      this.$('.thumb-image.thumb-image-square').attr('src', squareImageSrc);
    }
  },

  initTagEditor: function() {
    this.$('.input-taggable').select2({
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
});
