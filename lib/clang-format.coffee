exec = require('child_process').exec

module.exports =
class ClangFormat
  constructor: (state) ->
    atom.workspaceView.command 'clang-format:format', =>
      editor = atom.workspace.getActiveEditor()
      if editor
        @format(editor)

    atom.workspaceView.command 'core:save', (e) =>
      editor = atom.workspace.getActiveEditor()
      if editor
        scope = editor.getCursorScopes()[0]
        if atom.config.get('clang-format.formatOnSave') and scope is 'source.c++'
          @format editor, ->
            editor.save()

  format: (editor, onDone) ->
    if editor
      buffer = editor.getBuffer()
      exe = atom.config.get('clang-format.executable')
      style = atom.config.get('clang-format.style')
      cursor = buffer.characterIndexForPosition(editor.getCursorBufferPosition())
      cmd = exe + ' -cursor=' + cursor.toString() + ' -style ' + style
      if editor.getPath()
        cmd += ' -assume-filename=' + editor.getPath()
      child = exec cmd, (err, stdout, stderr) =>
        if err
          console.log(err)
          console.log(stdout)
          console.log(stderr)
          onDone() if onDone
        else
          [_, json, text] = stdout.match(/([^\r\n]+)\r?\n?([^]*)/)
          editor.setText(text)
          json = JSON.parse(json)
          editor.setCursorBufferPosition(
            buffer.positionForCharacterIndex(json.Cursor))
          onDone() if onDone
      child.stdin.end(editor.getText());
