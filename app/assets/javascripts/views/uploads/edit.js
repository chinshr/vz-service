App.Views.UploadsEdit = App.Views.UploadsBase.extend({
  template: JST['uploads/edit'],
  
  events: _.extend({
    'click .action-close' : 'replaceView',
    'keyup input': 'onFieldChange',
    'change select': 'onSelectionChange',
    'submit' : 'onFormSubmit'
  }, App.Views.UploadsBase.prototype.events),
  
  initialize: function() {
    App.Views.UploadsBase.prototype.initialize.call(this); // super
    
    _.defer((function(_this) {
      return function() {
        $('.input-taggable').select2({
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
                  id: item.id,
                  text: item.name
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
  },
  
  replaceView: function() {
    var edit = this;
    var show = new App.Views.UploadsShow({model: this.model});
    this.$el.replaceWith(show.render().el);
    edit.remove();
  },
  
  renderUpdate: function(hasProgress) {
    App.Views.UploadsBase.prototype.renderUpdate.call(this, hasProgress); // super

    // enable fields
    this.$("input[name='upload[title]']").val(this.model.attributes.title);
    this.$("select[name='upload[locale]']").val(this.model.attributes.locale);
    this.$("select[name='upload[tag_list]']").val(this.model.attributes.tag_list);
    this.$("select[name='upload[privacy]']").val(this.model.attributes.privacy);
    this.$("form, form input, form textarea, form button").removeAttr('disabled');
    this.$(".form-fields").show();
  },
  
  onFieldChange: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data  = {};
    if (key = field.attr('name').match(/\[(.+)\]/)[1]) {
      data[key] = field.val();
      this.model.set(data);
      return this.model.validate();
    }
  },

  onSelectionChange: function(e) {
    var data, field, key;
    field = $(e.currentTarget);
    data = {};
    if (key = field.attr('name').match(/\[(.+)\]/)[1]) {
      data[key] = field.val();
      this.model.set(data);
      return this.model.validate();
    }
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
});