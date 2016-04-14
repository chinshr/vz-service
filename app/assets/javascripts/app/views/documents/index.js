App.Views.DocumentsIndex = Backbone.View.extend({
  template: JST['documents/index'],
  layout: 'grid-item col-lg-2 col-md-3 col-sm-6 col-xs-12',
  offset: 0,
  limit: 25,

  initialize: function(options) {
    _.bindAll(this, "addOne", "addAll", "initPlayer", "renderCollection", "initInfiniteScroll", "fetchCollection");
    options = options || {};
    this.holder = options.holder || "#documents";
    this.query = options.query || {};
    this.layout = options.layout || this.layout;
    this.fetchCollection();
  },

  render: function() {
    var _this = this;
    this.$el.html(this.template);
    this.grid = this.$('.browser-grid');

    this.grid
      .on("arrangeComplete", function(event, filteredItems) {
        _this.refreshLayout();
      })
      .imagesLoaded()
        .progress(function(instance, image) {
          var result = image.isLoaded ? 'loaded' : 'broken';
          if (result === 'broken') {
            console.log( 'image is ' + result + ' for ' + image.img.src );
          }
        }).always(function(instance) {
          _this.initIsotope();
          _this.show();
        });

    _.defer(function() {
      _this.renderCollection();
      _this.initInfiniteScroll();
      _this.grid.imagesLoaded(function() {
        _this.refreshLayout(50, function(view) {
          _this.show();
        });
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
      element = $('<div data-type="' + (model.attributes.id ? 'instance' : 'new-instance') + '"></div>').addClass(this.layout);
    if (!_.isEmpty(model.attributes)) {
      view = new App.Views.DocumentsShowTile({model: model, parent: this});
      element.append(view.render({name: 'show-file-name.a'}).el);

      this.grid.imagesLoaded(function() {
        _this.grid.isotope('insert', element);
        _this.refreshLayout();
      });
    }
    return view;
  },

  addAll: function() {
    this.collection.each(this.addOne, this);
  },

  renderCollection: function(scroll) {
    var _this = this,
      elements = [],
      elementSelector = _this.grid.data("isotope").options.itemSelector;

    this.collection.each(function(model) {
      var view,
        element = $('<div data-type="instance"></div>').addClass(this.layout);

      view = new App.Views.DocumentsShowTile({parent: this, model: model});
      element = element.append(view.render().el);
      elements.push(element[0]);
    }, this);

    elements = $(elements).hide();

    elements.imagesLoaded()
      .progress(function(imgLoad, image) {
        var element = $(image.img).parents(elementSelector);
        element.show();
        if (!scroll) {
          _this.grid.isotope('insert', element);
          _this.grid.isotope({filter: "*"});
        } else {
          _this.grid.isotope('insert', element);
        }
      }).always(function() {
        _this.refreshLayout();
      });
    return this;
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

  refreshLayout: function(delay, callback) {
    var _this = this;
    if (this.grid.data('isotope')) {
      setTimeout(function() {
        _this.grid.isotope('layout');
        if (callback) {
          callback(_this);
        }
      }, delay || 50);
    }
  },

  initPlayer: function(options) {
    this.player = new App.Views.Player(_.extend({parent: this}, options)).render();
  },

  initInfiniteScroll: function() {
    var _this = this;

    document.addEventListener('scroll', function (event) {
      if (document.body.scrollHeight === document.body.scrollTop + window.innerHeight) {
        if (!_this.blockFetchCollection) {
          _this.blockFetchCollection = true;
          _this.fetchCollection(this);
        }
      }
    });
  },

  fetchCollection: function(scroll) {
    var _this           = this,
      collectionFetched = new $.Deferred;

    this.holder = $(this.holder);
    this.query  = _.extend(this.query, {
      'limit': this.limit,
      'offset': this.offset,
    });

    _this.collection = _this.collection || new App.Collections.Documents();
    _this.collection.fetch({
      reset: true,
      add: true,
      data: $.param(this.query),
      success: function(collection, response, xhr) {
        _this.collection = collection;
        if (!scroll || collection.length > 0) {
          // either initial render or endless scroll with results
          _this.offset += (collection.length > 0 ? Math.min(_this.limit, collection.length) : 0);
          _this.blockFetchCollection = false;
          collectionFetched.resolve();
        } else if (scroll && collection.length === 0) {
          // block for N secs when endless scroll without items
          _this.blockFetchCollection = true;
          setTimeout(function() {
            _this.blockFetchCollection = false;
          }, 5000);
        }
      },
      error: function(collection, response, xhr) {
        console.log("Error fetchCollection", collection, response, xhr);
      }
    });

    collectionFetched.done(function() {
      _this.listenToOnce(_this.collection, 'add', _this.addOne);
      _this.listenToOnce(_this.collection, 'reset', _this.addAll);

      if (!scroll) {
        _this.holder.html(_this.render().el);
      } else {
        // take care of by listeners
        // _this.renderCollection(scroll);
      }
    });
    return this;
  }

});
