App.Views.DocumentsEdit = App.Views.DocumentsBase.extend({
  template: JST['documents/edit'],

  render: function() {
    this.$el.html(this.template(this.model.attributes));

    if (this.model.ok) {
      this.initSharePopover().render();
      this.initPublishPopover().render();
      this.initEditor();
      this.initPlayer();
      this.initUserInitials();
      this.initContentEditorFormatPopover();
      this.initTagEditor();
      $('#document-loading').hide();
      $('#document-edit').show();

      _.defer((function(_this) {
        return function() {
          // $('#publish-document').on('click', _.bind(this.publish, this));
          $('#publish-document').on('click', function() { alert("wow!"); });
        }
      })(this));

    } else if (this.model.errors) {
      $('#loading').hide();
      $('#document-load-error').show();
    }

    return this;
  },

  initTagEditor: function() {
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
    }).on('change', (function(_this) {
      return function(event) {
        var tag_list = $(event.target).val();
        tag_list = tag_list.split(',');
        // console.log('tags current: ', _this.model.attributes);
        // console.log('tags new: ', tag_list);
        _this.model.set({tag_list: tag_list});
        // _this.saving();
      }
    })(this));
  },

  isEdit: function() { return true; }

});