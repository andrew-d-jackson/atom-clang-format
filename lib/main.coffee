ClangFormat = require './clang-format'

module.exports =
  configDefaults:
    executable: 'clang-format'
    formatOnSave: true
    style: 'file'

  activate: ->
    @clangFormat = new ClangFormat()

  deactivate: ->
    @clangFormat.destroy()
