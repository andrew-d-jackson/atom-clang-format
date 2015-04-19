ClangFormat = require './clang-format'

module.exports =
  config:
    formatOnSave:
      type: 'boolean'
      default: true
    executable:
      type: 'string'
      default: 'clang-format'
    style:
      type: 'string'
      default: 'file'

  activate: ->
    @clangFormat = new ClangFormat()

  deactivate: ->
    @clangFormat.destroy()
