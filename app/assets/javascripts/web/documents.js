/*
$(document).ready ->
  window['raptor'](".editor").raptor
    preset: 'inline'
*/


var titleEditor = new Quill('#title-editor', {
  modules: {
  },
  'styles': '/assets/web/quill-title-editor.css'
});


var contentEditor = new Quill('#content-editor', {
  modules: {
    'toolbar': {
      container: '#content-editor-toolbar-container'
    },
  },
  'styles': '/assets/web/quill-content-editor.css'
});

