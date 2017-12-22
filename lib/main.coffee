ClangFormat = require './clang-format'

module.exports =
  config:
    formatCPlusPlusOnSave:
      type: 'boolean'
      default: false
      title: 'Format C++ on save'
      order: 1
    formatCOnSave:
      type: 'boolean'
      default: false
      title: 'Format C on save'
      order: 2
    formatObjectiveCOnSave:
      type: 'boolean'
      default: false
      title: 'Format Objective-C on save'
      order: 3
    formatJavascriptOnSave:
      type: 'boolean'
      default: false
      title: 'Format JavaScript on save'
      order: 4
    formatTypescriptOnSave:
      type: 'boolean'
      default: false
      title: 'Format TypeScript on save'
      order: 5
    formatJavaOnSave:
      type: 'boolean'
      default: false
      title: 'Format Java on save'
      order: 6
    executable:
      type: 'string'
      default: ''
      order: 7
    style:
      type: 'string'
      default: 'file'
      order: 8
      description: 'Default "file" uses the file ".clang-format" in one of the parent directories of the source file.'
    fallbackStyle:
      type: 'string'
      default: 'llvm'
      description: 'Fallback Style. Set To "none" together with style "file" to ensure that if no ".clang-format" file exists, no reformatting takes place.'

  activate: ->
    @clangFormat = new ClangFormat()

  deactivate: ->
    @clangFormat.destroy()
