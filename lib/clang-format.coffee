exec = require('child_process').exec

module.exports =
  configDefaults:
    executable: 'clang-format'
    formatOnSave: true

  activate: (state) ->
    atom.project.eachEditor (editor) =>
      @attachEditor(editor)

    atom.workspaceView.command 'clang-format:format', =>
      editor = atom.workspace.getActiveEditor()
      if editor
        @format(editor)

  deactivate: ->
    atom.unsubscribe(atom.project)

  attachEditor: (editor) ->
    buffer = editor.getBuffer()

    atom.subscribe buffer, 'reloaded will-be-saved', =>
      scope = editor.getCursorScopes()[0]
      if atom.config.get('clang-format.formatOnSave') and scope is 'source.c++'
        @format(editor)

    atom.subscribe buffer, 'destroyed', ->
      atom.unsubscribe(editor.getBuffer())

  format: (editor) ->
    if editor and editor.getPath()
      cmd = atom.config.get('clang-format.executable')
      exec cmd + ' -style file ' + editor.getPath(), (err, stdout, stderr) ->
        if err
          console.log(err)
        else
          cursorpos = editor.getCursorBufferPosition()
          editor.setText(stdout)
          editor.setCursorBufferPosition(cursorpos)
