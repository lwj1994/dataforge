const vscode = require('vscode');
const { exec } = require('child_process');

function activate(context) {
  let disposable = vscode.commands.registerCommand('dataforge.runOnFile', function (uri) {
    if (uri && uri.fsPath) {
      const filePath = uri.fsPath;
      const dataforgeExecutable = 'dataforge';
      const command = `${dataforgeExecutable} ${filePath}`;

      exec(command, (error, stdout, stderr) => {
        if (error) {
          vscode.window.showErrorMessage(`Error executing DataForge: ${error.message}`);
          return;
        }
        if (stderr) {
          vscode.window.showWarningMessage(`DataForge stderr: ${stderr}`);
        }
        vscode.window.showInformationMessage(`DataForge output: ${stdout}`);
      });
    } else {
        vscode.window.showErrorMessage('No file selected.');
    }
  });

  context.subscriptions.push(disposable);
}

function deactivate() {}

module.exports = {
  activate,
  deactivate
}