/*
class App.Views.UploadsShow extends Backbone.View
  template: JST['uploads/show']
  events: 
    'click .cancel' : 'onCancelUpload'
    'submit' : 'onFormSubmit'
    'keyup input': 'fieldChanged'
    'change select': 'selectionChanged'
    'mouseenter .show-panel': 'hover'
    'mouseleave .show-panel': 'hover'
  
  render: ->
    @$el.html @template @model.attributes
    # Backbone.Validation.bind(@)
    @

  initialize: () ->
    @interval = null
    @listenTo(@model, 'upload:progress', @onUploadProgress)
    @listenTo(@model, 'destroy', @destroy)
    @listenToOnce(@model, 'sync', @onAfterCreate)

  hover: (e) ->
    if (e.type == 'mouseenter')
      $(e.currentTarget).find(".action-panel").addClass("hover");
    else
      $(e.currentTarget).find(".action-panel").removeClass("hover");

  onUploadProgress: (data) ->
    console.log data.percent
    console.log data.message
    @$('.progress .progress-bar').css('width', "#{data.percent}%")
    @$('.message').html(data.message);

    if data.percent == 100
      @_xhr = null
    else if !@_xhr
      # Else if @_xhr is not yet defined, save a reference to it
      @_xhr = data.xhr

  onCancelUpload: (e) ->
    # Leverage the saved xhr reference to abort() the upload
    if @_xhr
      @_xhr.abort()
    @stop()
    @$(".progress-panel").remove()
    
  onAfterCreate: (e) ->
    # fill form
    @$("input[name='upload[title]']").val(@model.attributes.title)
    @$("select[name='upload[locale]']").val(@model.attributes.locale)
    @$("select[name='upload[privacy]']").val(@model.attributes.privacy)
    
    @$('form, form input, form textarea, form button').removeAttr("disabled")
    @$(".form-fields").show()
    
    @$('.message').html(@model.message())
    @ping()
    
  onFormSubmit: (e) ->
    e.originalEvent.preventDefault()
    form = $(e.target)
    data = {}
    
    _.map form.serializeArray(), (n) ->
      key = n['name'].match(/\[(.+)\]/)
      data[key[1]] = n['value'] if key.length > 1
    @model.set(data)

    if @model.isValid(true)
      @$(".btn").button("loading")
      @model.sync 'update', @model,
        success: () =>
          @$(".btn").button("reset")
        error: () =>
          @$(".btn").button("reset")
    
  ping: ->
    @interval = setInterval =>
        @poll()
      , 2500

  stop: ->
    window.clearInterval(@interval)

  poll: ->
    @model.sync 'read', @model,
      success: (data) =>
        @model.set("progress", data.upload.progress)
        @model.set("status", data.upload.status)
      error: (model) =>
        console.log "error fetching upload ID = #{@data.upload.id}"
    
    @$('.message').html(@model.message())
    @$('.alert-slug-link').html("<a href=\"#{@model.attributes.slug}\" target=\"_blank\">http://voyz.es/#{@model.attributes.slug}</a>")
    @$('.alert-slug').show()

    @$('.progress .progress-bar').css('width', "#{@model.attributes.progress}%")

    # show progressbar motion
    if @model.hasProgress()
      @$('.progress').addClass('active')
    else
      @$('.progress').removeClass('active')

    # change status light
    if @model.hasFinished()
      @$('.status').
        removeClass('label-info').
        addClass('label-success')
      @stop()
    else if @model.hasStopped()
      @$('.status').
        removeClass('label-info').
        removeClass('label-success').
        removeClass('label-warning').
        addClass('label-danger')
      
    # change progress bar color to green when transcribing
    if !@$('.progress .progress-bar').hasClass('progress-bar-success')
      @$('.progress .progress-bar').removeClass('progress-bar-info')
      @$('.progress .progress-bar').addClass('progress-bar-success')

  fieldChanged: (e) ->
    field = $(e.currentTarget)
    data = {}
    if key = field.attr('name').match(/\[(.+)\]/)[1]
      data[key] = field.val()
      @model.set data
      #@model.isValid key
      @model.validate()
            
  selectionChanged: (e) ->
    field = $(e.currentTarget)
    data  = {}
    if key = field.attr('name').match(/\[(.+)\]/)[1]
      data[key] = field.val()
      @model.set(data)
      @model.validate()
*/
App.Views.UploadsShow = Backbone.View.extend({
  template: JST['uploads/show'],
  events: {
    'click .cancel' : 'onCancelUpload',
    'submit' : 'onFormSubmit',
    'keyup input': 'fieldChanged',
    'change select': 'selectionChanged',
    'mouseenter .show-panel': 'hover',
    'mouseleave .show-panel': 'hover'
  },
  
  render: function() {
    this.$el.html(this.template(this.model.attributes));
    return this;
  },
        
  initialize: function() {
    this.interval = null;
    this.listenTo(this.model, 'upload:progress', this.onUploadProgress);
    this.listenTo(this.model, 'destroy', this.destroy);
    return this.listenToOnce(this.model, 'sync', this.onAfterCreate);
  },
      
  hover: function(e) {
    if (e.type === 'mouseenter') {
      return $(e.currentTarget).find('.action-panel').addClass('hover');
    } else {
      return $(e.currentTarget).find('.action-panel').removeClass('hover');
    }
  },

  onUploadProgress: function(data) {
    console.log(data.percent);
    console.log(data.message);
    this.$('.progress .progress-bar').css('width', '' + data.percent + '%');
    this.$('.message').html(data.message);
    if (data.percent === 100) {
      return this._xhr = null;
    } else if (!this._xhr) {
      return this._xhr = data.xhr;
    }
  },

  onCancelUpload: function(e) {
    if (this._xhr) {
      this._xhr.abort();
    }
    this.stop();
    return this.$(".progress-panel").remove();
  },
    
  onAfterCreate: function(e) {
    this.$("input[name='upload[title]']").val(this.model.attributes.title);
    this.$("select[name='upload[locale]']").val(this.model.attributes.locale);
    this.$("select[name='upload[privacy]']").val(this.model.attributes.privacy);
    this.$('form, form input, form textarea, form button').removeAttr("disabled");
    this.$(".form-fields").show();
    this.$('.message').html(this.model.message());
    return this.ping();
  },
    
  onFormSubmit: function(e) {
    var data, form;
    e.originalEvent.preventDefault();
    form = $(e.target);
    data = {};
    _.map(form.serializeArray(), function(n) {
      var key;
      key = n['name'].match(/\[(.+)\]/);
      if (key.length > 1) {
        return data[key[1]] = n['value'];
      }
    });
    this.model.set(data);
    if (this.model.isValid(true)) {
      this.$(".btn").button("loading");
      return this.model.sync('update', this.model, {
        success: (function(_this) {
          return function() {
            return _this.$(".btn").button("reset");
          };
        })(this),
        error: (function(_this) {
          return function() {
            return _this.$(".btn").button("reset");
          };
        })(this)
      });
    }
  },
  
  ping: function() {
    return this.interval = setInterval((function(_this) {
      return function() {
        return _this.poll();
      };
    })(this), 2500);
  },
      
  stop: function() {
    return window.clearInterval(this.interval);
  },
      
  poll: function() {
    this.model.sync('read', this.model, {
      success: (function(_this) {
        return function(data) {
          _this.model.set("progress", data.upload.progress);
          return _this.model.set("status", data.upload.status);
        };
      })(this),
      error: (function(_this) {
        return function(model) {
          return console.log("error fetching upload ID = " + _this.data.upload.id);
        };
      })(this)
    });
    this.$('.message').html(this.model.message());
    this.$('.alert-slug-link').html("<a href=\"" + this.model.attributes.slug + "\" target=\"_blank\">http://voyz.es/" + this.model.attributes.slug + "</a>");
    this.$('.alert-slug').show();
    this.$('.progress .progress-bar').css('width', "" + this.model.attributes.progress + "%");
    if (this.model.hasProgress()) {
      this.$('.progress').addClass('active');
    } else {
      this.$('.progress').removeClass('active');
    }
    if (this.model.hasFinished()) {
      this.$('.status').removeClass('label-info').addClass('label-success');
      this.stop();
    } else if (this.model.hasStopped()) {
      this.$('.status').removeClass('label-info').removeClass('label-success').removeClass('label-warning').addClass('label-danger');
    }
    if (!this.$('.progress .progress-bar').hasClass('progress-bar-success')) {
      this.$('.progress .progress-bar').removeClass('progress-bar-info');
      return this.$('.progress .progress-bar').addClass('progress-bar-success');
    }
  },
  
  fieldChanged: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data  = {};
    if (key = field.attr('name').match(/\[(.+)\]/)[1]) {
      data[key] = field.val();
      this.model.set(data);
      return this.model.validate();
    }
  },
            
  selectionChanged: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data = {};
    if (key = field.attr('name').match(/\[(.+)\]/)[1]) {
      data[key] = field.val();
      this.model.set(data);
      return this.model.validate();
    }
  }
});