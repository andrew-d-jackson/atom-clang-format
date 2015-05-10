exec = require('child_process').exec
path = require('path')

module.exports =
class ClangFormat
  constructor: (state) ->
    atom.workspace.observeTextEditors (editor) =>
      @handleBufferEvents(editor)

    @commands = atom.commands.add 'atom-workspace',
     'clang-format:format', =>
        editor = atom.workspace.getActiveTextEditor()
        if editor
          @format(editor)

  destroy: ->
    @commands.dispose()
    atom.unsubscribe(atom.project)

  handleBufferEvents: (editor) ->
    editor.onDidSave =>
      scope = editor.getRootScopeDescriptor().scopes[0]
        @format(editor)


  format: (editor) ->
    if editor and editor.getPath()
      exe = atom.config.get('clang-format.executable')
      style = atom.config.get('clang-format.style')
      cursor = @getCurrentCursorPosition(editor)

      command = exe + ' -cursor=' + cursor.toString() +
                       ' -style=' + style

      if (@textSelected(editor))
        command += ' -lines=' + @getTargetLineNums(editor)

      file_path = editor.getPath()
      working_dir = path.dirname(file_path)
      child = exec command, {cwd: working_dir}, (err, stdout, stderr) =>
        if err
          console.log(err)
          console.log(stdout)
          console.log(stderr)
        else
          editor.setText(@getReturnedFormattedText(stdout))
          returnedCursorPos = @getReturnedCursorPosition(stdout)
          convertedCursorPos = editor.getBuffer().positionForCharacterIndex(returnedCursorPos)
          editor.setCursorBufferPosition(convertedCursorPos)

      child.stdin.write(editor.getText())
      child.stdin.end()


  shouldFormatOnSaveForScope: (scope) ->
    if atom.config.get('clang-format.formatCPlusPlusOnSave') and scope in ['source.c++', 'source.cpp']
      return true
    if atom.config.get('clang-format.formatCOnSave') and scope in ['source.c']
      return true
    if atom.config.get('clang-format.formatObjectiveCOnSave') and scope in ['source.objc', 'source.objcpp']
      return true
    return false

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

  getCursorLineNumber: (editor) ->
    cursorPosition = editor.getCursorBufferPosition()
    # +1 to get 1-base line number.
    return cursorPosition.toArray()[0] + 1

  textSelected: (editor) ->
    range = editor.getSelectedBufferRange()
    return !range.isEmpty()

  getSelectedLineNums: (editor) ->
    range = editor.getSelectedBufferRange()
    rows = range.getRows()
    # + 1 to get 1-base line number.
    starting_row = rows[0] + 1
    # If 2 lines are selected, the diff between |starting_row| is 1, so -1.
    ending_row = starting_row + range.getRowCount() - 1
    return [starting_row, ending_row]

  # Returns line numbers recognizable by clang-format, i.e. '<begin>:<end>'.
  getTargetLineNums: (editor) ->
    if (@textSelected(editor))
      line_nums = @getSelectedLineNums(editor)
      return line_nums[0] + ':' + line_nums[1]

    line_num = @getCursorLineNumber(editor)
    return line_num + ':' + line_num
