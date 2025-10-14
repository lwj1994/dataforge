package com.melu.dataforge;

import java.nio.charset.StandardCharsets;

import org.jetbrains.annotations.NotNull;

import com.intellij.execution.ExecutionException;
import com.intellij.execution.configurations.GeneralCommandLine;
import com.intellij.execution.filters.TextConsoleBuilderFactory;
import com.intellij.execution.process.OSProcessHandler;
import com.intellij.execution.process.ProcessAdapter;
import com.intellij.execution.process.ProcessEvent;
import com.intellij.execution.process.ProcessHandler;
import com.intellij.execution.process.ProcessOutputTypes;
import com.intellij.execution.ui.ConsoleView;
import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.CommonDataKeys;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.progress.ProgressIndicator;
import com.intellij.openapi.progress.ProgressManager;
import com.intellij.openapi.progress.Task;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.Key;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.openapi.wm.ToolWindow;
import com.intellij.openapi.wm.ToolWindowManager;
import com.intellij.ui.content.Content;
import com.intellij.ui.content.ContentFactory;

public class DataForgeAction extends AnAction {
    private static final Logger LOG = Logger.getInstance(DataForgeAction.class);

    public DataForgeAction() {
        super();
        LOG.info("DataForgeAction constructor called - Action is being registered");
        LOG.info("DataForgeAction class loaded: " + this.getClass().getName());
        LOG.info("DataForgeAction instance created: " + this.toString());
    }

    @Override
    public void update(@NotNull AnActionEvent e) {
        LOG.info("DataForgeAction.update() called");
        Project project = e.getProject();
        if (project == null) {
            LOG.warn("Project is null in actionPerformed");
            e.getPresentation().setEnabledAndVisible(false);
            return;
        }

        // 简化的文件检测逻辑
        VirtualFile file = getCurrentFile(e);
        
        // Show for any file, not directory
        boolean visible = file != null && !file.isDirectory();
        e.getPresentation().setEnabledAndVisible(visible);
        
        if (visible) {
            LOG.info("Menu item visible for file: " + file.getPath());
        }
    }

    @Override
    public void actionPerformed(@NotNull AnActionEvent e) {
        LOG.info("DataForgeAction.actionPerformed() called");
        Project project = e.getProject();
        if (project == null) {
            LOG.warn("Project is null in actionPerformed");
            return;
        }

        VirtualFile file = getCurrentFile(e);
        
        if (file == null) {
            LOG.warn("Could not determine the current file");
            return;
        }
        
        LOG.info("Executing dataforge command for file: " + file.getPath());

        final String filePath = file.getPath();
        final String projectPath = project.getBasePath();
        final VirtualFile finalFile = file;

        try {
            GeneralCommandLine commandLine = new GeneralCommandLine("dataforge", "--path", filePath);
            if (projectPath != null) {
                commandLine.setWorkDirectory(projectPath);
            }
            commandLine.setCharset(StandardCharsets.UTF_8);

            final ProcessHandler processHandler = new OSProcessHandler(commandLine);
            
            // Show console on EDT
            showConsole(project, processHandler);

            // Execute command with progress indicator
            ProgressManager.getInstance().run(new Task.Backgroundable(project, "Running DataForge", false) {
                @Override
                public void run(@NotNull ProgressIndicator indicator) {
                    indicator.setText("Preparing DataForge command...");
                    indicator.setIndeterminate(true);
                    
                    // Add process listener to capture output and update progress
                    final StringBuilder outputBuffer = new StringBuilder();
                    processHandler.addProcessListener(new ProcessAdapter() {
                        @Override
                        public void onTextAvailable(@NotNull ProcessEvent event, @NotNull Key outputType) {
                            String text = event.getText().trim();
                            if (!text.isEmpty()) {
                                outputBuffer.append(text).append("\n");
                                if (outputType == ProcessOutputTypes.STDOUT || outputType == ProcessOutputTypes.STDERR) {
                                    String displayText = text.length() > 100 ? text.substring(0, 100) + "..." : text;
                                    indicator.setText("DataForge: " + displayText);
                                }
                            }
                        }
                        
                        @Override
                        public void processWillTerminate(@NotNull ProcessEvent event, boolean willBeDestroyed) {
                            indicator.setText("DataForge process finishing...");
                        }
                        
                        @Override
                        public void processTerminated(@NotNull ProcessEvent event) {
                            if (event.getExitCode() == 0) {
                                indicator.setText("DataForge execution completed successfully");
                            } else {
                                indicator.setText("DataForge execution failed with exit code: " + event.getExitCode());
                            }
                        }
                    });
                    
                    indicator.setText("Executing DataForge on " + finalFile.getName() + "...");
                    
                    // Start the process
                    processHandler.startNotify();
                    
                    // Wait for process to complete
                    processHandler.waitFor();
                }
            });
        } catch (ExecutionException ex) {
            LOG.error("Failed to execute dataforge command", ex);
        }
    }
    
    /**
     * 获取当前文件的方法，尝试多种方式
     */
    private VirtualFile getCurrentFile(@NotNull AnActionEvent e) {
        VirtualFile file = null;
        
        // 方式1: 直接从VIRTUAL_FILE获取
        file = e.getData(CommonDataKeys.VIRTUAL_FILE);
        if (file != null) {
            LOG.info("Got file from VIRTUAL_FILE: " + file.getPath());
            return file;
        }
        
        // 方式2: 从VIRTUAL_FILE_ARRAY获取
        VirtualFile[] files = e.getData(CommonDataKeys.VIRTUAL_FILE_ARRAY);
        if (files != null && files.length > 0) {
            file = files[0];
            LOG.info("Got file from VIRTUAL_FILE_ARRAY: " + file.getPath());
            return file;
        }
        
        // 方式3: 从当前编辑器获取
        try {
            com.intellij.openapi.editor.Editor editor = e.getData(CommonDataKeys.EDITOR);
            if (editor != null) {
                com.intellij.openapi.fileEditor.FileDocumentManager fdm = com.intellij.openapi.fileEditor.FileDocumentManager.getInstance();
                file = fdm.getFile(editor.getDocument());
                if (file != null) {
                    LOG.info("Got file from current editor: " + file.getPath());
                    return file;
                }
            }
        } catch (Exception ex) {
            LOG.warn("Error getting file from editor: " + ex.getMessage());
        }
        
        // 方式4: 从PSI文件获取
        try {
            com.intellij.psi.PsiFile psiFile = e.getData(CommonDataKeys.PSI_FILE);
            if (psiFile != null) {
                file = psiFile.getVirtualFile();
                if (file != null) {
                    LOG.info("Got file from PSI: " + file.getPath());
                    return file;
                }
            }
        } catch (Exception ex) {
            LOG.warn("Error getting file from PSI: " + ex.getMessage());
        }
        
        // 方式5: 尝试从项目树选择获取
        try {
            com.intellij.pom.Navigatable navigatable = e.getData(CommonDataKeys.NAVIGATABLE);
            if (navigatable instanceof com.intellij.psi.PsiFile) {
                file = ((com.intellij.psi.PsiFile) navigatable).getVirtualFile();
                if (file != null) {
                    LOG.info("Got file from Navigatable: " + file.getPath());
                    return file;
                }
            }
        } catch (Exception ex) {
            LOG.warn("Error getting file from Navigatable: " + ex.getMessage());
        }
        
        // 方式6: 尝试从文件编辑器管理器获取当前文件
        try {
            Project project = e.getProject();
            if (project != null) {
                com.intellij.openapi.fileEditor.FileEditorManager fem = com.intellij.openapi.fileEditor.FileEditorManager.getInstance(project);
                VirtualFile[] openFiles = fem.getOpenFiles();
                if (openFiles.length > 0) {
                    // 获取当前选中的文件
                    VirtualFile selectedFile = fem.getSelectedFiles().length > 0 ? fem.getSelectedFiles()[0] : openFiles[0];
                    if (selectedFile != null) {
                        LOG.info("Got file from FileEditorManager: " + selectedFile.getPath());
                        return selectedFile;
                    }
                }
            }
        } catch (Exception ex) {
            LOG.warn("Error getting file from FileEditorManager: " + ex.getMessage());
        }
        
        LOG.warn("Could not get current file from any method");
        return null;
    }

    private void showConsole(Project project, ProcessHandler processHandler) {
        ToolWindow toolWindow = ToolWindowManager.getInstance(project).getToolWindow("Run");
        if (toolWindow == null) {
            LOG.warn("Cannot find 'Run' tool window.");
            return;
        }

        // Remove existing "DataForge" console if it exists
        Content existingContent = null;
        for (Content content : toolWindow.getContentManager().getContents()) {
            if ("DataForge".equals(content.getDisplayName())) {
                existingContent = content;
                break;
            }
        }
        if (existingContent != null) {
            toolWindow.getContentManager().removeContent(existingContent, true);
        }

        // Create a new console
        ConsoleView consoleView = TextConsoleBuilderFactory.getInstance().createBuilder(project).getConsole();
        Content newContent = ContentFactory.getInstance().createContent(consoleView.getComponent(), "DataForge", false);
        toolWindow.getContentManager().addContent(newContent);
        
        // Attach process and activate
        consoleView.attachToProcess(processHandler);
        toolWindow.getContentManager().setSelectedContent(newContent);
        toolWindow.activate(null);
    }
}