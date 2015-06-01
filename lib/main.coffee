ClangFormat = require './clang-format'

module.exports =
  config:
    formatCPlusPlusOnSave:
      type: 'boolean'
      default: true
    formatCOnSave:
      type: 'boolean'
      default: true
    formatObjectiveCOnSave:
      type: 'boolean'
      default: true
    formatJavascriptOnSave:
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
