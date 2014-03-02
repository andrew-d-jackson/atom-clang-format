exec = require('child_process').exec

ClangFormatStatusView = require('./clang-format-status-view')

module.exports =
  view: null

  configDefaults:
    executable: 'clang-format'
    formatOnSave: true

  activate: (state) ->
    @view = new ClangFormatStatusView(state.viewState)
    atom.project.eachEditor (editor) =>
      @attachEditor(editor)
    atom.subscribe atom.project, 'editor-created', (editor) =>
      @attachEditor(editor)

    atom.workspaceView.command 'clang-format:format', =>
      editor = atom.workspace.getActiveEditor()
      if editor
        @format(editor)

  deactivate: ->
    @view.destroy()
    atom.unsubscribe(atom.project)

  serialize: ->
    viewState: @view.serialize()

  attachEditor: (editor) ->
    atom.subscribe editor.getBuffer(), 'reloaded saved', =>
      if atom.config.get('clang-format.formatOnSave')
        @format(editor)
    atom.subscribe editor.getBuffer(), 'destroyed', =>
      atom.unsubscribe(editor.getBuffer())

  format: (editor) ->
    if editor and editor.getPath()
      scope = editor.getCursorScopes()[0]
      if scope is 'source.c++'
        editorView = atom.workspaceView.getActiveView()
        if editorView.gutter and editorView.gutter.attached
          editorView.gutter.removeClassFromAllLines('clang-format-error')
          editorView.gutter.find('.clang-format-error-msg').remove()

        cmd = atom.config.get('clang-format.executable')
        exec cmd + ' -i ' + editor.getPath(), (err, stdout, stderr) =>
          if not err or err.code is 0
            @view.html('').hide()
          else
            message = 'Format error.'
            if stderr.match(/No such file or directory/)
              message = 'Cannot find clang-format executable.'
            editorView = atom.workspaceView.getActiveView()
            if editorView.gutter and editorView.gutter.attached
              stderr.split(/\r?\n/).forEach (line) ->
                match = line.match(/^.+?:(\d+):(\d+):\s+(.+)/)
                if match
                  lineNo = parseInt(match[1]) - 1
                  editorView.gutter.addClassToLine(lineNo, 'clang-format-error')
                  lineEl = editorView.gutter.find('.line-number-' + lineNo)
                  if lineEl.size() > 0
                    lineEl.prepend('<abbr class="clang-format-error-msg" title="' +
                      match[2] + ': ' + match[3] + '">✘</abbr>')

            @view.html('<span class="error">' + message + '</span>').show()
