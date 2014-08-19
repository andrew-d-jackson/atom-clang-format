exec = require('child_process').exec

module.exports =
class ClangFormat
  constructor: (state) ->
    atom.workspace.eachEditor (editor) =>
      @handleBufferEvents(editor)

    atom.workspaceView.command 'clang-format:format', =>
      editor = atom.workspace.getActiveEditor()
      if editor
        @format(editor)

  destroy: ->
    atom.unsubscribe(atom.project)

  handleBufferEvents: (editor) ->
    buffer = editor.getBuffer()
    atom.subscribe buffer, 'saved', =>
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
      cursor = @getCurrentCursorPosition(editor)
      exec exe + ' -cursor=' + cursor.toString() + ' -style ' + style + ' "' + path + '"', (err, stdout, stderr) =>
        if err
          console.log(err)
          console.log(stdout)
          console.log(stderr)
        else
          editor.setText(@getReturnedFormattedText(stdout))
          returnedCursorPos = @getReturnedCursorPosition(stdout)
          convertedCursorPos = @convertReturnedCursorPosition(editor, returnedCursorPos)
          editor.setCursorScreenPosition(convertedCursorPos)

  getEndJSONPosition: (text) ->
    for i in [0..(text.length-1)]
      if text[i] is '\n' or text[i] is '\r'
        return i+1
    return -1

  getReturnedCursorPosition: (stdout) ->
    parsed = JSON.parse stdout.slice(0, @getEndJSONPosition(stdout))
    return parsed.Cursor

  getReturnedFormattedText: (stdout) ->
    return stdout.slice(@getEndJSONPosition(stdout))

  getCurrentCursorPosition: (editor) ->
    cursorPosition = editor.getCursorBufferPosition()
    text = editor.getTextInBufferRange([[0, 0], cursorPosition])
    return text.length

  convertReturnedCursorPosition: (editor, position) ->
    text = editor.getText()
    x = y = 0

    for i in [0..(text.length-1)]
      if position is 0
        return [y, x]
      else if text[i] is '\n' or text[i] is '\r' or text[i] is '\f'
        x = 0
        y++
      else
        x++
      position--

    return [y, x]
