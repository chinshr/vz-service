// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.core
//= require jquery.ui.widget
//= require lib/chosen.jquery
//= require lib/select2
//= require lib/bootstrap
//= require lib/rails.validations
//= require lib/rails.validations.bootstrap
//= require lib/detect_timezone
//= require underscore
//= require backbone
//= require lib/backbone/backbone.validation
//= require lib/backbone/backbone.validation.config
//= require lib/s3upload
//= require web/documents
//= require app
//= require_tree ../templates
//= require_tree ./models
//= require_tree ./collections
//= require_tree ./views
//= require_tree ./routers
//= require_tree ./web


jQuery.extend({
  /* 
   *  E.g. $.alert("This is an error!", "error"); 
   */
  alert: function(text, options) {
    options = _.extend(options || {}, {});
    
    var html = '<div id="alert-modal" class="modal fade alert-modal bs-example-modal-sm">' +
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
            '<button type="button" class="btn btn-primary" data-dismiss="modal">Ok</button>' +
          '</div>' +
        '</div><!-- /.modal-content -->' +
      '</div><!-- /.modal-dialog -->' +
    '</div><!-- /.modal -->';
    
    $("#alert-modal").remove();
    $('body').append(html);
    $('#alert-modal').modal();
  },
  
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
      callback(true);
    });
    $("#confirm-modal .btn-cancel").bind("click", function() {
      callback(false);
    });
  }
});
