{View} = require 'atom'

module.exports =
class ClangFormatStatusView extends View
  @content: ->
    @div class: 'clang-format-status inline-block'

  destroy: ->
    @detach()

  initialize: ->
    setTimeout((=> @attach()), 0)

  attach: ->
    statusbar = atom.workspaceView.statusBar
    statusbar.appendRight this
