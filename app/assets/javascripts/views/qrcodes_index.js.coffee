class Qscribe.Views.QrcodesIndex extends Backbone.View
  template: JST['qrcodes/index']

  events:
    'change input#Files': 'onChangeFiles'
      
  render:->
    @$el.html @template
    @