App.Views.UploadsShow = App.Views.UploadsBase.extend({
  template: JST['uploads/show'],
  
  events: _.extend({
    'click .action-update' : 'replaceView',
    'click .action-edit' : 'openEdit',
    'click .action-preview' : 'openPreview',
  }, App.Views.UploadsBase.prototype.events),
  
  initialize: function() {
    _.defer((function(_this) {
      return function() {
        _this.ping();
      }
    })(this));
  },

  render: function() {
    // super
    App.Views.UploadsBase.prototype.render.call(this, {});
    
    _.defer((function(_this) {
      return function() {
        $('.btn-dropdown-toggle').dropdown();
      }
    })(this));
    
    return this;
  },
  
  replaceView: function() {
    var show     = this;
    var showHTML = show.$el;
    var edit     = new App.Views.UploadsEdit({model: this.model});
    var editHTML = $(edit.render(this.model.attributes).el);
    
    editHTML.find('.panel').css({
      'transform': 'rotateY(180deg)',
      '-webkit-transform': 'rotateY(180deg)',
      'position': 'absolute',
      'top': '0',
      'left': '0',
      'width': '100%'
    }).appendTo(showHTML.find('.flipper'));
    
    showHTML.find('.tile').addClass('flip');
    showHTML.find('.tile').bind('animationend webkitTransitionEnd oanimationend MSAnimationEnd', (function(_this) {
      return function(e) {
        _this.$el.replaceWith(edit.render().el);
        show.remove();
      }
      console.log("=> transition ended");
    })(this));
  },

  openEdit: function() {
    alert('open edit document');
  },

  openPreview: function() {
    alert('open preview document');
  }
});