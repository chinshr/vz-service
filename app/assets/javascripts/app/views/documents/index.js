App.Views.DocumentsIndex = Backbone.View.extend({
  template: JST['documents/index'],

  offset: 0,
  limit: 25,

  initialize: function() {
    _.bindAll(this, "addOne", "addAll", "initPlayer", "renderCollection", "initScroll", "fetchCollection");
    this.fetchCollection();
  },

  render: function() {
    var _this = this;
    this.$el.html(this.template);

    _.defer(function() {
      _this.initIsotope();
      _this.renderCollection();
      _this.initScroll();
      _this.grid.imagesLoaded(function() {
        setTimeout(function() {
          _this.refreshLayout();
          _this.show();
        }, 10);
      });
    });
    return this;
  },

  show: function() {
    $('#content-loading').hide();
    NProgress.done();
  },

  showPageError: function() {
    $('#loading').hide();
    $('#load-error').show();
  },

  addOne: function(model, response) {
    var _this = this,
      view,
      grid = this.$('.browser-grid'),
      item = $('<div class="grid-item col-lg-2 col-md-3 col-sm-6 col-xs-12" data-type="' + (model.attributes.id ? 'instance' : 'new-instance') + '"></div>');

    if (!_.isEmpty(model.attributes)) {
      if (model.attributes.editable) {
        view = new App.Views.DocumentsEditTile({model: model, parent: this});
        item.append(view.render({name: 'edit-file-name.a'}).el);
      } else {
        view = new App.Views.DocumentsShowTile({model: model, parent: this});
        item.append(view.render({name: 'show-file-name.a'}).el);
      }

      _this.initIsotope();

      // Isotope add items:
      // http://isotope.metafizzy.co/v1/docs/adding-items.html
      grid.imagesLoaded(function() {
        grid.isotope('insert', item);
        grid.isotope('reveal', grid.data('isotope').items);
      });

      return view;
    }
  },

  addAll: function() {
    this.collection.each(this.addOne, this);
  },

  initIsotope: function() {
    this.grid = this.$('.browser-grid');

    this.grid.isotope({
      itemSelector: '.grid-item',
      layoutMode: 'masonry',
      percentPosition: false,
      isInitLayout: true,
      animationEngine: 'best-available',
      masonry: {
        columnWidth: 0
      },
      // sort by number
      sortBy: ['type', 'number'],
      sortAscending : false,
      getSortData: {
        'type': '[data-type]',
        'number': function (elem) {
          return parseInt($(elem).find('.number').text(), 10);
        }
      }
    });

    return this.grid;
  },

  refreshLayout: function() {
    if (this.grid.data('isotope')) {
      this.grid.isotope('layout');
    }
  },

  initPlayer: function(options) {
    this.player = new App.Views.Player(_.extend({parent: this}, options)).render();
  },

  renderCollection: function(scroll) {
    var gridEl = this.$('.browser-grid'),
      elements = [];

    this.collection.each(function(model) {
      var view,
        element = $('<div class="grid-item col-lg-2 col-md-3 col-sm-6 col-xs-12" data-type="instance"></div>');

      view = new App.Views.DocumentsShowTile({parent: this, model: model});
      element = element.append(view.render().el);
      elements.push(element[0]);
    }, this);

    // Isotope add items:
    // http://isotope.metafizzy.co/v1/docs/adding-items.html
    gridEl.imagesLoaded(function() {
      if (!scroll) {
        gridEl.isotope('insert', elements);
        gridEl.isotope('reveal', gridEl.data('isotope').items);
      } else {
        gridEl.isotope('insert', elements);
      }
    });

    return this;
  },

  initScroll: function() {
    var _this = this;

    document.addEventListener('scroll', function (event) {
      if (document.body.scrollHeight === document.body.scrollTop + window.innerHeight) {
        if (!_this.blockFetchCollection) {
          _this.fetchCollection(this);
        }
      }
    });
  },

  fetchCollection: function(scroll) {
    var _this           = this,
      collection        = new App.Collections.Documents(),
      collectionFetched = new $.Deferred,
      userUid           = $('#documents').data('user-uid');

    collection.fetch({
      reset: true,
      data: $.param({
        'limit': this.limit,
        'offset': this.offset,
        'sort_order': {'published_at': 'desc'},
        'user_id': userUid,
        'any_of_status': [1]
      }),
      success: function(collection, response, xhr) {
        _this.collection = collection;
        if (collection.length > 0) {
          _this.offset += _this.limit;
          collectionFetched.resolve();
        } else if (scroll) {
          _this.blockFetchCollection = true;
          setTimeout(function() {
            _this.blockFetchCollection = false;
          }, 5000);
        }
      }
    });

    collectionFetched.done(function() {
      _this.listenTo(_this.collection, 'add', _this.addOne);
      _this.listenTo(_this.collection, 'reset', _this.addAll);

      if (!scroll) {
        $('#documents').html(_this.render().el);
      } else {
        _this.renderCollection(scroll);
      }
    });

    return this;
  }

});