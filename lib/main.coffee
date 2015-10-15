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
      default: false
    formatJavascriptOnSave:
      type: 'boolean'
      default: false
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
