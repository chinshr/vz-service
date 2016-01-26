$.extend({
  /*
   *  E.g. $.confirm("This is an error!", function(result) { result ? true : false });
   */
  confirm: function(text, callback) {
    var title;
    //options = _.extend(options || {}, {});

    var html = '<div id="confirm-modal" class="modal fade confirm-modal bs-example-modal-sm">' +
      '<div class="modal-dialog">' +
        '<div class="modal-content">' +
          (!!title ?
          '<div class="modal-header">' +
            '<button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>' +
            '<h4 class="modal-title">' + title + '</h4>' +
          '</div>' : "" ) +
          '<div class="modal-body">' +
            '<p>' + text + '</p>' +
          '</div>' +
          '<div class="modal-footer">' +
            '<button type="button" class="btn btn-default btn-cancel" data-dismiss="modal">Cancel</button>' +
            '<button type="button" class="btn btn-primary btn-ok" data-dismiss="modal">OK</button>' +
          '</div>' +
        '</div><!-- /.modal-content -->' +
      '</div><!-- /.modal-dialog -->' +
    '</div><!-- /.modal -->';

    $("#confirm-modal").remove();
    $('body').append(html);
    $('#confirm-modal').modal({

    });
    $("#confirm-modal .btn-ok").bind("click", function() {
      if (callback) {
        callback(true);
      }
    });
    $("#confirm-modal .btn-cancel").bind("click", function() {
      if (callback) {
        callback(false);
      }
    });
  }
});
