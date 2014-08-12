ClangFormat = require './clang-format'

module.exports =
  configDefaults:
    formatOnSave: true
    executable: 'clang-format'
    style: 'file'

  activate: ->
    @clangFormat = new ClangFormat()

  deactivate: ->
    @clangFormat.destroy()
