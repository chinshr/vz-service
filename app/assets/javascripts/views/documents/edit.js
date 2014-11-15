App.Views.DocumentsEdit = Backbone.View.extend({
  template: JST['documents/edit'],

  events: {
//    'drop #drop-box': 'dropFiles',
  },

  initialize: function() {
    this.listenTo(this.model, 'change', this.render);
    this.model.fetch({
      success: (function(_this) {
        return function(model, response, options) {
          console.log("=> fetched: success");
          _this.model.ok = true;
          _this.render();
        }
      })(this),
      error: (function(_this) {
        return function(model, response, options) {
          console.log("=> fetched: error");
          _this.model.ok = false;
          _this.model.errors = [{code: response.status, text: response.statusText}];
          _this.render();
        }
      })(this)

    });
  },

  render: function() {
    this.$el.html(this.template);

    if (this.model.ok) {
      $('#document-loading').hide();
      $('#document-edit').show();
    } else if (this.model.errors) {
      $('#document-load-error').show();
    }

    return this;
  },

});