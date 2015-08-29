{CompositeDisposable} = require 'atom'
{execSync} = require 'child_process'

module.exports =
class ClangFormat
  constructor: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @handleBufferEvents(editor)

    @subscriptions.add atom.commands.add 'atom-workspace',
      'pretty-format:format', =>
        editor = atom.workspace.getActiveTextEditor()
        if editor
          @format(editor)

    @subscriptions.add atom.commands.add 'atom-workspace',
      'pretty-format:format-at-point', =>
        editor = atom.workspace.getActiveTextEditor()
        if editor
          @format(editor, true)

  destroy: ->
    @subscriptions.dispose()

  handleBufferEvents: (editor) ->
    buffer = editor.getBuffer()
    bufferSavedSubscription = buffer.onWillSave =>
      scope = editor.getRootScopeDescriptor().scopes[0]
      if @shouldFormatOnSaveForScope scope
        buffer.transact => @format(editor)

    editorDestroyedSubscription = editor.onDidDestroy =>
      bufferSavedSubscription.dispose()
      editorDestroyedSubscription.dispose()

      @subscriptions.remove(bufferSavedSubscription)
      @subscriptions.remove(editorDestroyedSubscription)

    @subscriptions.add(bufferSavedSubscription)
    @subscriptions.add(editorDestroyedSubscription)

  yapfCmd: (editor, at_point) ->
    exe = atom.config.get('pretty-format.yapfExecutable')

    options = {}
    if @textSelected(editor) || at_point
      options.lines = @getTargetLineNums(editor, '-')
    args = ("--#{k}=\"#{v}\"" for k, v of options).join ' '
    return [exe, args]


  clangFormatCmd: (editor, at_point) ->
    exe = atom.config.get('pretty-format.clangFormatExecutable')
    options =
      style: atom.config.get('pretty-format.clangFormatStyle')
      cursor: @getCurrentCursorPosition(editor).toString()

    # Format only selection
    if @textSelected(editor) || at_point
      options.lines = @getTargetLineNums(editor)

    # Pass file path to clang-format so it can look for .clang-format files
    if file_path = editor.getPath()
      options['assume-filename'] = file_path

    args = ("-#{k}=\"#{v}\"" for k, v of options).join ' '
    return [exe, args]

  format: (editor, at_point=false) ->
    buffer = editor.getBuffer()

    scope = editor.getRootScopeDescriptor().scopes[0]
    if scope = 'source.python'
      [exe, args] = @yapfCmd(editor, at_point)
    else:
      [exe, args] = @clangFormatCmd(editor, at_point)

    # Call clang-format synchronously to ensure that save waits for us
    # Don't catch errors to make them visible to users via atom's UI
    # We need to explicitly ignore stderr since there is no parent stderr on
    # windows and node.js will try to write to it - whether it's there or not
    options = input: editor.getText(), stdio: ['pipe', 'pipe', 'ignore']

    try
      stdout = execSync("#{exe} #{args}", options).toString()
        # Update buffer with formatted text. setTextViaDiff minimizes re-rendering
      buffer.setTextViaDiff @getReturnedFormattedText(stdout)
        # Restore cursor position
      returnedCursorPos = @getReturnedCursorPosition(stdout)
      convertedCursorPos = buffer.positionForCharacterIndex(returnedCursorPos)
      editor.setCursorBufferPosition(convertedCursorPos)

    catch error
      if error.message.indexOf("Command failed:") < 0
        throw error
      else
        atom.confirm
          message: "ClangFormat Command Failed"
          detailedMessage: "This error is most often caused by not having
                            #{exe} installed and on your path. If you do
                            please create an issue on our github page."
          buttons:
            Okay: (->)


  shouldFormatOnSaveForScope: (scope) ->
    if atom.config.get('pretty-format.formatCPlusPlusOnSave') and scope in ['source.c++', 'source.cpp']
      return true
    if atom.config.get('pretty-format.formatCOnSave') and scope in ['source.c']
      return true
    if atom.config.get('pretty-format.formatObjectiveCOnSave') and scope in ['source.objc', 'source.objcpp']
      return true
    if atom.config.get('pretty-format.formatJavascriptOnSave') and scope in ['source.js']
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
  getTargetLineNums: (editor, sep=':') ->
    if (@textSelected(editor))
      line_nums = @getSelectedLineNums(editor)
      return line_nums[0] + sep + line_nums[1]

    line_num = @getCursorLineNumber(editor)
    return line_num + sep + line_num
