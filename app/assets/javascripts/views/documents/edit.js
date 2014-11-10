App.Views.DocumentsEdit = Backbone.View.extend({
  template: JST['documents/edit'],

  events: {
//    'drop #drop-box': 'dropFiles',
  },

  initialize: function() {
    // this.listenTo(this.collection, 'add', this.addUploadView);
  },

  render: function() {
    this.$el.html(this.template);
    _.defer((function(_this) {
      return function() {
        // $.ready()
        this.$('document-loading').hide();
        alert('document ready!');
      }
    })(this));
    return this;
  },

});