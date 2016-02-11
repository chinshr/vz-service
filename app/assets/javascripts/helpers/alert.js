$.extend({
  /*
   *  E.g. $.alert("This is an error!", {"title": "error"});
   */
  alert: function(text, options) {
    options = _.extend(options || {}, {});
    var title = options.title || "";

    var html = '<div id="alert-modal" class="modal fade alert-modal bs-example-modal-sm">' +
      '<div class="modal-dialog">' +
        '<div class="modal-content">' +
          (!!title ?
          '<div class="modal-header">' +
            '<button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>' +
            '<h4 class="modal-title">' + title + '</h4>' +
          '</div>' : '') +
          '<div class="modal-body">' +
            '<p>' + text + '</p>' +
          '</div>' +
          '<div class="modal-footer">' +
            '<button type="button" class="btn btn-primary" data-dismiss="modal">OK</button>' +
          '</div>' +
        '</div><!-- /.modal-content -->' +
      '</div><!-- /.modal-dialog -->' +
    '</div><!-- /.modal -->';

    $("#alert-modal").remove();  // close any existing alerts
    $('body').append(html);
    $('#alert-modal').modal();
  }

});
