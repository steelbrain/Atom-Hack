# Source: https://github.com/lukehoban/atom-ide-flow/blob/master/lib/tooltip-view.coffee
{$, View} = require 'atom'

module.exports = (Main)->
  LeBody = $(document.body)
  class TooltipView extends View
    @content: ->
      @div class: 'ide-hack-tooltip'

    initialize: (rect, @LeMessage) ->
      @append LeMessage
      LeBody.append this
      Coords = [rect.right, rect.bottom, undefined]
      Offset = 10

      # x axis adjust
      if Coords[0] + this[0].OffsetWidth >= LeBody.width()
        Coords[0] = LeBody.width() - this[0].OffsetWidth - Offset
      if Coords[0] < 0
        this.css({ 'white-space': 'pre-wrap' })
        Coords[0] = Offset
        Coords[2] = Offset

      # y axis adjust
      if Coords[1] + this[0].OffsetHeight >= LeBody.height()
        Coords[1] = @rect.top - this[0].OffsetHeight

      this.css({ left: Coords[0], top: Coords[1], right: Coords[2] })
