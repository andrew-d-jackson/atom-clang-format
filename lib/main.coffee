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
      default: ''
    style:
      type: 'string'
      default: 'file'
    fallbackStyle:
      type: 'string'
      default: 'none'

  activate: ->
    @clangFormat = new ClangFormat()

  deactivate: ->
    @clangFormat.destroy()
