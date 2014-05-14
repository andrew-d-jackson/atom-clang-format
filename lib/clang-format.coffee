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
          editor.setText(stdout)
          editor.setCursorBufferPosition(cursorpos)
