exec = require('child_process').exec

module.exports =
class ClangFormat
  constructor: (state) ->
    atom.project.eachEditor (editor) =>
      @handleBufferEvents(editor)

    atom.workspaceView.command 'clang-format:format', =>
      editor = atom.workspace.getActiveEditor()
      if editor
        @format(editor)

  destroy: ->
    atom.unsubscribe(atom.project)

  handleBufferEvents: (editor) ->
    buffer = editor.getBuffer()
    atom.subscribe buffer, 'reloaded will-be-saved', =>
      scope = editor.getCursorScopes()[0]
      if atom.config.get('clang-format.formatOnSave') and scope is 'source.c++'
        @format(editor)

    atom.subscribe buffer, 'destroyed', ->
      atom.unsubscribe(editor.getBuffer())

  format: (editor) ->
    if editor and editor.getPath()
      exe = atom.config.get('clang-format.executable')
      style = atom.config.get('clang-format.style')
      path = editor.getPath()
      exec exe + ' -style ' + style + ' "' + path + '"', (err, stdout, stderr) ->
        if err
          console.log(err)
        else
          cursorpos = editor.getCursorBufferPosition()
          textUptoPos = editor.getText(new Range(new Point(0, 0), cursorpos))
          charAmount = getAmountOfChars(textUptoPos)

          editor.setText(stdout)

          newPos = getPosFromAmount(charAmount, editor.getText())
          editor.setCursorBufferPosition(newPos)

  getAmountOfChars: (text) ->
    count = 0
    for i in [0..text.length]
      if i isnt '\n' and i isnt ' ' and i isnt '\t'  and i isnt '\r'
        count++
    return count

  getPosFromAmount: (amount, text) ->
    x = 0
    y = 0
    count = amount
    for i in [0..text.length]
      if i is '\n' or i is '\r'
        x = 0
        y++
      else if i isnt ' ' and i isnt '\t'
        count--
        x++
      else
        x++

      if count is 0
        return new Point(x, y)
    return new Point(x, y)
