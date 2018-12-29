'use babel';

import ClangFormat from '../lib/clang-format';

describe('When we format a simple c++ file', () => {
  let editor;

  beforeEach(async () => {
    editor = await atom.workspace.open('somefile.cpp');
    await editor.setText('#include"hello.cpp";int main(){return 0;}');
    await editor.setCursorBufferPosition(11);

    const clangFormatInstance = new ClangFormat();
    await clangFormatInstance.format(editor);
  });

  it('Should update the editor with the formatted code', async () => {
    expect(editor.getText()).toEqual('#include "hello.cpp"; int main(){return 0; }');
  });

  it('Should update the editor cursor position to stay on the same letter', async () => {
    expect(editor.getCursorBufferPosition()).toEqual(12);
  });
});
