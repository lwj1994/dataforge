package com.melu.dataforge;

import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.startup.ProjectActivity;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/**
 * Plugin startup activity to log plugin initialization
 */
public class DataForgePluginStartup implements ProjectActivity {
    private static final Logger LOG = Logger.getInstance(DataForgePluginStartup.class);

    @Nullable
    @Override
    public Object execute(@NotNull Project project, @NotNull Continuation<? super Unit> continuation) {
        LOG.info("DataForge Plugin initialized for project: " + project.getName());
        LOG.info("DataForge Plugin startup activity completed");
        return null;
    }
}