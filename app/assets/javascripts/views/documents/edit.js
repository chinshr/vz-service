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
          _this.model.errors = [{code: response.status, message: response.statusText}];
          _this.render();
        }
      })(this)

    });
  },

  render: function() {
    this.$el.html(this.template);

    if (this.model.ok) {
      $('#document-loading').hide();
      this.initializeEditor();
      $('#document-edit').show();
    } else if (this.model.errors) {
      $('#document-load-error').show();
    }

    return this;
  },

  initializeEditor: function() {
    this.titleEditor = new Quill('#title-editor', {
      'modules': {
      },
      'styles': '/assets/web/quill-title-editor.css'
    });

    this.contentEditor = new Quill('#content-editor', {
      'modules': {
        'toolbar': {
          container: '#content-editor-toolbar-container'
        },
      },
      'styles': '/assets/web/quill-content-editor.css'
    });

    this.contentEditor.addContainer('spacer-container');
    this.contentEditor.onModuleLoad('toolbar', function(toolbar) {
      $('#content-editor iframe').contents().find('body').css('overflow', 'hidden');
    });

    this.contentEditor.on('text-change', (function(_this) {
      return function(delta, source) {
        // expand window
        $('#content-editor').height(_this.contentEditor.root.ownerDocument.body.scrollHeight);
        _this.moveUserInitials();
      }
    })(this));

    this.contentEditor.on('selection-change', (function(_this) {
      return function(range) {
        if (range) {
          if (range.start == range.end) {
            // console.log('User cursor is on', range.start);
            _this.moveUserInitials();
          } else {
            // var text = editor.getText(range.start, range.end);
            // console.log('User has highlighted', text);
          }
        } else {
          // console.log('Cursor not in the editor');
        }
      }
    })(this));

    var keyboard = this.contentEditor.getModule('keyboard');
    keyboard.addHotkey({key: 32, metaKey: true, shiftKey: true}, function(range) {
      console.log('user hit Shift+Cmd+Space');
      return true;   // return false will prevent other listeners from receiving the event
    });

  },

  moveUserInitials: function() {
    var sel = this.contentEditor.root.ownerDocument.getSelection();
    if (sel && sel.rangeCount > 0) {
      var selrg = sel.getRangeAt(0);
      if (selrg) {
        var rects = selrg.getClientRects();
        if (rects.length > 0) {
          var ui = $(".user-initials");
          ui.stop().animate({
            top: 100 - (ui.height() / 2) + rects[0].top
          }, 50);
        }
      }
    }
  }

});