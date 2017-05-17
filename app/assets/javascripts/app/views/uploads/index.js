App.Views.UploadsIndex = Backbone.View.extend({
  template: JST['uploads/index'],
  layout: 'grid-item col-lg-2 col-md-3 col-sm-6 col-xs-12',
  offset: 0,
  limit: 15,

  events: {
    'drop #drop-box': 'dropFiles',
    'mouseenter #drop-box': 'addHover',
    'mouseleave #drop-box': 'removeHover',
    'change #file-locale': 'setLocale',
    'click button#upload-source': 'openSourceModal',
    'click .copy-email-to-clipboard': 'copyEmailToClipboard'
  },

  initialize: function(options) {
    _.bindAll(this, "initSourceModal", "initUnload",
      "initDropTarget", "addHover", "removeHover", "trigger",
      "addOne", "addAll", "renderCollection", "addFiles", "dropFiles",
      "dropzone", "uploadToS3", "setLocale",
      "refreshUploadCallback", "refreshLayout", "sourceModalSuccess",
      "initPlayer", "initInfiniteScroll", "fetchCollection", "processRefreshUpload");

    options = options || {};
    this.progressViews = {};
    this.layout = options.layout || this.layout;
    this.initPubnub();
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
      _this.initDropTarget();
      _this.initUnload();
      _this.initSourceModal();
      _this.setLocale();
      _this.initImageUploadInput();
      $('[data-toggle="tooltip"]').tooltip({
        container: 'body'
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

  // Instantiate and render new views for models added to the collection
  // This is the view that will be listening to the 'upload:progress' event,
  // and can also allow the user to cancel the upload
  addOne: function(model, response) {
    var _this = this,
      view,
      element = $('<div data-type="' + (model.attributes.id ? 'instance' : 'new-instance') + '"></div>').addClass(this.layout);

    if (!_.isEmpty(model.attributes)) {
      view = new App.Views.UploadsShowTile({model: model, parent: this});
      // if (model.attributes.editable) {
      //   view = new App.Views.UploadsEditTile({model: model, parent: this});
      // } else {
      //   view = new App.Views.UploadsShowTile({model: model, parent: this});
      // }
      element.append(view.render().el);

      this.grid.imagesLoaded(function() {
        _this.grid.isotope('insert', element);
        _this.refreshLayout();
      });

      this.progressViews[model.cid] = view;
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

      if (model.attributes.editable) {
        view = new App.Views.UploadsEditTile({model: model, parent: this});
      } else {
        view = new App.Views.UploadsShowTile({model: model, parent: this});
      }
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

  views: function() {
    return _(this.progressViews).pairs().filter(_.last).map(_.last);
  },

  initUnload: function() {
    var _this = this;
    var confirm = function(event) {
      if (_.any(_this.views(), function(v) { return v.model.isUploading() })) {
        return 'All uploads will be canceled if you leave this page.';
      }
    };
    window.onbeforeunload = confirm;
  },

  initDropTarget: function() {
    var dropTarget = $('#drop-box'),
      body = $('body'),
      showDrag = false,
      timeout = -1,
      _this = this;

    body.on('dragenter', function (event) {
      event.originalEvent.preventDefault();
      event.originalEvent.stopPropagation();
      console.log("=> dragenter");
      body.addClass('hover');
      dropTarget.addClass('hover');
      showDrag = true;
    }).on('dragover', function(event){
      event.originalEvent.preventDefault()
      event.originalEvent.stopPropagation()
      showDrag = true;
    }).on('dragleave', function (event) {
      event.originalEvent.preventDefault()
      event.originalEvent.stopPropagation()
      showDrag = false;
      clearTimeout( timeout );
      timeout = setTimeout(function() {
        if (!showDrag) {
          dropTarget.removeClass('hover');
          body.removeClass('hover');
        }
      }, 200 );
    });
  },

  initSourceModal: function() {
    this.sourceModal = new App.Views.UploadsSourceModal({
      parent: this,
      metadata: this.getUploadMetadata(),
      callbacks: {
        success: this.sourceModalSuccess
      }
    });
    return this.sourceModal;
  },

  sourceModalSuccess: function() {
    var _this = this;
    _.defer(function() {
      // this.sourceModal.destroy();
      _this.initSourceModal();
    });
  },

  sourceModalError: function(response) {
    console.log(response);
  },

  addHover: function(event) {
    if (event) {
      $(event.currentTarget).addClass('hover');
    }
  },

  removeHover: function(event) {
    if (event) {
      $(event.currentTarget).removeClass('hover');
    }
    $('body').removeClass('hover');
  },

  addFiles: function(e) {
    if ($(e.target).val() === '') {
      return;
    }

    return this.uploadToS3({
      dropped: false,
      selector: '#files'
    });
  },

  dropFiles: function(event) {
    event.originalEvent.preventDefault();

    if (event.dataTransfer === null) {
      return;
    }

    this.removeHover(event);

    return this.uploadToS3({
      dropped: true,
      files: event.originalEvent.dataTransfer.files
    });
  },

  dropzone: function(event) {
    event.originalEvent.preventDefault();
    event.originalEvent.stopPropagation();
  },

  getUploadMetadata: function() {
    var config = App.currentUser.attributes.properties.config;
    if (config.transcription && VZ.query.te) {
      config.transcription.engine = VZ.query.te;
    }
    return {
      "config": config
    };
  },

  uploadToS3: function(options) {
    var _this = this,
      newUploads = {};

    return new S3Upload({
      dropped: options.dropped,
      files: options.files,
      selector: options.selector,
      s3SignURL: 'api/account/uploads/signed_s3_put.json',

      onProgress: function(xhr, file, percent, status) {
        var upload;
        if (!xhr && percent === 0) {
          upload = new App.Models.Upload({
            type: 'Upload::MediaUpload',
            file_name: file.name,
            file_type: file.type,
            file_size: parseFloat(file.size),
            locale: _this.$("#file-locale").val() || "en-US",
            privacy: "private",
            editable: true,
            metadata: _this.getUploadMetadata()
          });
          newUploads[file.size] = upload;
          return _this.collection.add(upload);
        } else {
          upload = newUploads[file.size];
          if (upload) {
            return upload.trigger('upload:progress', {
              percent: percent,
              status: status,
              xhr: xhr
            });
          }
        }
      },

      onAbort: function(file, status) {
        var upload;
        upload = newUploads[file.size];
        upload.destroy();
        delete newUploads[file.size];
      },

      onFinishS3Put: function(publicUrl, file) {
        var upload = newUploads[file.size];
        if (upload) {
          return upload.save({source_url: publicUrl});
        }
      },

      onError: function(file, status) {
        var upload;
        // console.log('Upload error: ', status);
        upload = newUploads[file.size];
        upload.destroy();
        return delete newUploads[file.size];
      }
    });
  },

  setLocale: function() {
    var emailAddress = "my@voyz.es",
      emailLocale = "";

    this.locale = $("#file-locale").val();
    emailLocale = (this.locale || "").toLowerCase();

    // enable / disable step
    if (_.isEmpty(this.locale)) {
      this.$('.select-upload-type-step').addClass("disabled").removeClass("enabled");
    } else {
      this.$('.select-upload-type-step').addClass("enabled").removeClass("disabled");
    }

    // email locale
    if (this.locale === "en" || this.locale === "en-US" || _.isEmpty(this.locale)) {
      emailLocale = "";
    }
    // email address
    if (emailLocale && emailLocale.length >= 0) {
      emailAddress = "my+" + emailLocale + "@voyz.es";
    }
    this.$('.email-file-link').attr('value', emailAddress);
  },

  mailtoHref: function(locale, emailAddress) {
    var href,
      text = $("#file-locale option:selected").text() + " {" + $("#file-locale").val() + "}";
    // locale
    if (!locale) {
      locale = $("#file-locale").val().toLowerCase()
      if (locale === "en" || locale === "en-us") {
        locale = "";
      } else if (locale.indexOf("-") !== -1) {
        locale = locale.split("-")[0];
      }
    }
    // email address
    if (!emailAddress) {
      emailAddress = "my@voyz.es";
      if (locale && locale.length >= 0) {
        emailAddress = "my+" + locale + "@voyz.es";
      }
    }
    href = "mailto:" + emailAddress +
      "?subject=Your%20title" +
      "&body=—%0DAttach media files to process for " + text + ". Change title and add description above the line.";
    return href
  },

  openSourceModal: function() {
    this.sourceModal.render().show({locale: this.locale});
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
      }, delay || 100);
    }
  },

  initPubnub: function() {
    var _this = this;

    this.refreshQueue = [];

    this.pubnub = PUBNUB.init({
      publish_key: VZ.config.pubnub.publish_key,
      subscribe_key: VZ.config.pubnub.subscribe_key,
      ssl: VZ.isSSL()
    });

    this.pubnub.subscribe({
      channel: this.pubnubChannel(),
      message: this.refreshUploadCallback,
      state: App.currentUser.attributes
    });

    this.refreshQueueInterval = setInterval(function() {
      _this.refreshQueue.sort(function(a, b) { return a.sequence > b.sequence}).forEach(function(message) {
        // console.log("-> message: ", message);
        // remove from refreshQueue
        var index = _.findIndex(_this.refreshQueue, function(m) { return m.sequence === message.sequence });
        if (index > -1) {
          _this.refreshQueue.splice(index, 1);
        }
        // ...then process message
        _this.processRefreshUpload(message["refresh-upload"]);
      });
    }, 100);
  },

  processRefreshUpload: function(envelope) {
    if (envelope) {
      var _this = this,
        _model = _this.collection.find(function(m) { return m.attributes.uid === envelope.upload_uid; });
      if (!!_model) {
        // existing upload
        _model.set(envelope);
      } else {
        // new upload
        _model = new App.Models.Upload({id: envelope.upload_id});
        _model.fetch({
          success: function() {
            _this.collection.add(_model);
          },
          error: function(model, xhr, options) {
            // may have been deleted, so refresh
            _this.refreshLayout();
          }
        });
      }
    }
  },

  clearUploadQueueTimer: function() {
    if (this.refreshQueueInterval) {
      return clearInterval(this.refreshQueueInterval);
    }
  },

  pubnubChannel: function() {
    return "vz-user-" + App.currentUser.attributes.uid;
  },

  refreshUploadCallback: function(message) {
    if (message["refresh-upload"] && message["refresh-upload"].upload_type === "Upload::MediaUpload") {
      this.refreshQueue.push(message);
    }
  },

  initPlayer: function(options) {
    this.player = new App.Views.Player(_.extend({parent: this}, options)).render();
  },

  initInfiniteScroll: function() {
    var _this = this;

    _this.listenTo(_this.collection, 'add', _this.addOne);
    _this.listenToOnce(_this.collection, 'reset', _this.addAll);
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

    _this.collection = _this.collection || new App.Collections.AccountUploads();
    _this.collection.fetch({
      remove: false,
      data: $.param({
        'limit': this.limit,
        'offset': this.offset,
        'sort_order': {'created_at': 'desc'},
        'any_of_types': ['media_upload']
      }),
      success: function(collection, response, xhr) {
        var length = response.uploads.length;
        if (!scroll || length > 0) {
          // either initial render or endless scroll with results
          _this.offset += (length > 0 ? Math.min(_this.limit, length) : 0);
          _this.blockFetchCollection = false;
          collectionFetched.resolve();
        } else if (scroll && length === 0) {
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
      if (!scroll) {
        $('#uploads').html(_this.render().el);
      }
    });
    return this;
  },

  initImageUploadInput: function() {
    var _this = this,
      input = this.$('input.upload-files-input:file');

    this.$('#upload-files').each(function () {
      var button = $(this);
      // input.after(clone).detach();
      // $.cleanData(input.unbind('remove'));

      button
        .on('click', function(e) {
          var form, clone = input.clone(true);
          e.stopPropagation();
          e.preventDefault();

          clone
            .removeClass('upload-files-input')
            .attr('id', 'files')
            .on('click', function(e) {
              e.stopPropagation();
            })
            .on('change', _this.addFiles);

          button.parent().find('.upload-files-form').remove();
          form = $('<form class="upload-files-form"></form>').append(clone);
          form[0].reset();
          button.parent().append(form);
          clone.click();
        });
    });
  },

  copyEmailToClipboard: function(event) {
    var el = $(event.currentTarget),
      input = el.parent().parent().find('input'),
      value = input.attr('value'),
      originalTitle = el.attr('data-original-title');

    event.originalEvent.preventDefault();
    input.select();
    document.execCommand("copy");
    el.attr('data-original-title', el.data('copiedTitle'));
    el.on('hidden.bs.tooltip', function () {
      el.attr('data-original-title', originalTitle);
    })
    setTimeout(function() {
      el.tooltip('show');
    }, 10);
  }

});
