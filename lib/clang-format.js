'use babel';

import { CompositeDisposable } from 'atom';
import { execSync } from 'child_process';
import os from 'os';
import path from 'path';
import clangFormatExecutables from 'clang-format';

export default class ClangFormat {
  constructor() {
    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.workspace.observeTextEditors(editor => this.handleBufferEvents(editor)),
    );

    this.subscriptions.add(atom.commands.add('atom-workspace', 'clang-format:format', () => {
      const editor = atom.workspace.getActiveTextEditor();
      if (editor) {
        this.format(editor);
      }
    }));
  }

  destroy = () => {
    this.subscriptions.dispose();
  }

  handleBufferEvents = (editor) => {
    const buffer = editor.getBuffer();
    const bufferSavedSubscription = buffer.onWillSave(() => {
      const scope = editor.getRootScopeDescriptor().scopes[0];
      if (this.shouldFormatOnSaveForScope(scope)) {
        buffer.transact(() => this.format(editor));
      }
    });

    const editorDestroyedSubscription = editor.onDidDestroy(() => {
      bufferSavedSubscription.dispose();
      editorDestroyedSubscription.dispose();

      this.subscriptions.remove(bufferSavedSubscription);
      this.subscriptions.remove(editorDestroyedSubscription);
    });

    this.subscriptions.add(bufferSavedSubscription);
    this.subscriptions.add(editorDestroyedSubscription);
  }

  format = (editor) => {
    const buffer = editor.getBuffer();

    let exe = atom.config.get('clang-format.executable');
    if (!exe) {
      const exePackageLocation = path.dirname(clangFormatExecutables.location);
      if (os.platform() === 'win32') {
        exe = `${exePackageLocation}/bin/win32/clang-format.exe`;
      } else {
        exe = `${exePackageLocation}/bin/${os.platform()}_${os.arch()}/clang-format`;
      }
    }

    const options = {
      style: atom.config.get('clang-format.style'),
      cursor: this.getCurrentCursorPosition(editor).toString(),
      'fallback-style': atom.config.get('clang-format.fallbackStyle'),
    };

    // Format only selection
    if (this.textSelected(editor)) {
      options.lines = this.getTargetLineNums(editor);
    }

    // Pass file path to clang-format so it can look for .clang-format files
    const filePath = editor.getPath();
    if (filePath) {
      options['assume-filename'] = filePath;
    }

    // Call clang-format synchronously to ensure that save waits for us
    // Don't catch errors to make them visible to users via atom's UI
    // We need to explicitly ignore stderr since there is no parent stderr on
    // windows and node.js will try to write to it - whether it's there or not
    const args = Object.keys(options).reduce((memo, optionKey) => {
      const optionValue = options[optionKey];
      if (optionValue) {
        return `${memo}-${optionKey}="${optionValue}" `;
      }
      return memo;
    }, '');

    const execOptions = { input: editor.getText(), stdio: ['pipe', 'pipe', 'ignore'] };

    if (filePath) {
      execOptions.cwd = path.dirname(filePath);
    }

    try {
      const stdout = execSync(`"${exe}" ${args}`, execOptions).toString();
      // Update buffer with formatted text. setTextViaDiff minimizes re-rendering
      buffer.setTextViaDiff(this.getReturnedFormattedText(stdout));
      // Restore cursor position
      const returnedCursorPos = this.getReturnedCursorPosition(stdout);
      const convertedCursorPos = buffer.positionForCharacterIndex(returnedCursorPos);
      return editor.setCursorBufferPosition(convertedCursorPos);
    } catch (error) {
      if (error.message.indexOf('Command failed:') < 0) {
        throw error;
      } else {
        return atom.confirm({
          message: 'ClangFormat Command Failed',
          detailedMessage: 'This error is most often caused by not having clang-format installed and on your path. If you do please create an issue on our github page.',
          buttons: {
            Okay: () => {},
          },
        });
      }
    }
  }


  shouldFormatOnSaveForScope = (scope) => {
    if (atom.config.get('clang-format.formatCPlusPlusOnSave') && ['source.c++', 'source.cpp'].includes(scope)) {
      return true;
    }
    if (atom.config.get('clang-format.formatCOnSave') && ['source.c'].includes(scope)) {
      return true;
    }
    if (atom.config.get('clang-format.formatObjectiveCOnSave') && ['source.objc', 'source.objcpp'].includes(scope)) {
      return true;
    }
    if (atom.config.get('clang-format.formatJavascriptOnSave') && ['source.js'].includes(scope)) {
      return true;
    }
    if (atom.config.get('clang-format.formatTypescriptOnSave') && ['source.ts'].includes(scope)) {
      return true;
    }
    if (atom.config.get('clang-format.formatJavaOnSave') && ['source.java'].includes(scope)) {
      return true;
    }
    return false;
  }

  getEndJSONPosition = (text) => {
    for (let i = 0; i < text.length; i += 1) {
      if ((text[i] === '\n') || (text[i] === '\r')) {
        return i + 1;
      }
    }

    return -1;
  }

  getReturnedCursorPosition = (stdout) => {
    if (!stdout) { return 0; }
    const parsed = JSON.parse(stdout.slice(0, this.getEndJSONPosition(stdout)));
    return parsed.Cursor;
  }

  getReturnedFormattedText = stdout => stdout.slice(this.getEndJSONPosition(stdout));

  getCurrentCursorPosition = (editor) => {
    const cursorPosition = editor.getCursorBufferPosition();
    const text = editor.getTextInBufferRange([[0, 0], cursorPosition]);
    return text.length;
  }

  getCursorLineNumber = (editor) => {
    const cursorPosition = editor.getCursorBufferPosition();
    // +1 to get 1-base line number.
    return cursorPosition.toArray()[0] + 1;
  }

  textSelected = (editor) => {
    const range = editor.getSelectedBufferRange();
    return !range.isEmpty();
  }

  getSelectedLineNums = (editor) => {
    const range = editor.getSelectedBufferRange();
    const rows = range.getRows();
    // + 1 to get 1-base line number.
    const startingRow = rows[0] + 1;
    // If 2 lines are selected, the diff between |starting_row| is 1, so -1.
    const endingRow = (startingRow + range.getRowCount()) - 1;
    return [startingRow, endingRow];
  }

  // Returns line numbers recognizable by clang-format, i.e. '<begin>:<end>'.
  getTargetLineNums = (editor) => {
    if (this.textSelected(editor)) {
      const lineNums = this.getSelectedLineNums(editor);
      return `${lineNums[0]}:${lineNums[1]}`;
    }

    const lineNum = this.getCursorLineNumber(editor);
    return `${lineNum}:${lineNum}`;
  }
}
