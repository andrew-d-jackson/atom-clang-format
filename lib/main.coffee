ClangFormat = require './clang-format'

module.exports =
  config:
    formatOnSaveScopes:
      type: 'array'
      item:
        type: 'string'
      default: [
        'source.c'
        'source.c++'
        'source.cpp'
        'source.objc'
        'source.objcpp'
      ]
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
