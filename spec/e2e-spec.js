'use babel';

describe("when the package is loaded in atom", () => {
  it("should format the file when clang-format:format is called", async () => {
    const editor = await atom.workspace.open('somefile.cpp');
    await atom.packages.activatePackage('clang-format');
    await editor.setText('#include"hello.cpp";int main(){return 0;}');
    await atom.commands.dispatch(atom.views.getView(atom.workspace), 'clang-format:format');
    expect(editor.getText()).toEqual('#include "hello.cpp"; int main(){return 0; }');
  });
});
