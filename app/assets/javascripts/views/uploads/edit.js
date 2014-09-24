App.Views.UploadsEdit = App.Views.UploadsBase.extend({
  template: JST['uploads/edit'],
  
  events: _.extend({
    'click .action-close' : 'replaceView',
  }, App.Views.UploadsBase.prototype.events),
  
  initialize: function() {
    this.tags = ["red", "green", "blue", "purple"];
    _.defer((function(_this) {
      return function() {
        $('.input-taggable').select2({
          minimumInputLength: 3,
          multiple: true,
          ajax: {
            url: window.location.protocol + "//" + window.location.host + "/api/tags.json",
            dataType: 'json',
            quietMillis: 100,
            data: function (term, page) { // page is the one-based page number tracked by Select2
              return {
                named_like: term, //search term
                limit: 10, // page size
                offset: (page - 1) * 10 // page number
              };
            },
            results: function (data, page) {
              // var more = (page * 10) < data.total; // whether or not there are more results available

              // notice we return the value of more so Select2 knows if more results can be loaded

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
          maximumInputLength: 15,
          tokenSeparators: [",", " "]
        });
      }
    })(this));
  },
  
  replaceView: function() {
    var edit = this;
    var show = new App.Views.UploadsShow({model: this.model});
    this.$el.replaceWith(show.render().el);
    edit.remove();
  }
});