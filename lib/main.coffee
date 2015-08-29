ClangFormat = require './prettifier'

module.exports =
  config:
    formatCPlusPlusOnSave:
      type: 'boolean'
      default: false
    formatCOnSave:
      type: 'boolean'
      default: false
    formatObjectiveCOnSave:
      type: 'boolean'
      default: false
    formatJavascriptOnSave:
      type: 'boolean'
      default: false
    clangFormatExecutable:
      type: 'string'
      default: 'clang-format'
    clangFormatStyle:
      type: 'string'
      default: 'file'

  activate: ->
    @clangFormat = new ClangFormat()

  deactivate: ->
    @clangFormat.destroy()
