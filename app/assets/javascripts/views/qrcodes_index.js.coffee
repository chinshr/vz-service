class Qscribe.Views.QrcodesIndex extends Backbone.View
  template: JST['qrcodes/index']

  render:->
    @$el.html @template
    @