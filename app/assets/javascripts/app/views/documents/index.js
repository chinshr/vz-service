App.Views.DocumentsIndex = Backbone.View.extend({
  template: JST['documents/index'],

  initialize: function() {
    _.bindAll(this, "addView", "addAll");

    this.listenTo(this.collection, 'add', this.addView);
    this.listenTo(this.collection, 'reset', this.addAll);
  },

  render: function() {
    var _this = this;
    this.$el.html(this.template);

    this.addAll();

    _.defer(function() {
      _this.initIsotope();
      _this.grid.imagesLoaded(function() {
        _this.refreshLayout();
        _this.show();
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

  addView: function(model, response) {
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
    this.collection.each(this.addView, this);
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
  }

});