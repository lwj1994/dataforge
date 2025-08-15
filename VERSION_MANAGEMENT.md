# 版本管理系统使用说明

本项目使用统一的版本管理系统来管理主包（`data_class_gen`）和注解包（`dataclass_annotation`）的版本号，确保两个包的版本保持同步。

## 文件结构

```
├── version.yaml              # 版本配置文件
├── tools/
│   └── update_version.dart   # 版本管理脚本
├── pubspec.yaml              # 主包配置
└── annotation/
    └── pubspec.yaml          # 注解包配置
```

## 配置文件说明

### version.yaml

这是版本管理的核心配置文件，包含以下配置：

```yaml
# 当前版本号
version: "0.1.1"

# 包配置
packages:
  # 主包配置
  data_class_gen:
    path: "."
    pubspec: "pubspec.yaml"
    
  # annotation包配置
  dataclass_annotation:
    path: "annotation"
    pubspec: "pubspec.yaml"

# 版本更新配置
version_config:
  sync_all: true
  format: "semantic"
  update_changelog: true
```

**配置说明：**
- `version`: 当前统一版本号
- `packages`: 需要管理的包列表
  - `path`: 包的相对路径
  - `pubspec`: pubspec.yaml文件名
- `version_config`: 版本管理配置
  - `sync_all`: 是否同步更新所有包
  - `format`: 版本号格式（semantic = 语义化版本）
  - `update_changelog`: 是否自动更新CHANGELOG

## 使用方法

### 1. 显示当前版本信息

```bash
dart tools/update_version.dart --show
```

或使用简写：

```bash
dart tools/update_version.dart -s
```

**输出示例：**
```
当前版本配置:
==============================
配置版本: 0.1.1

包版本信息:
  data_class_gen: 0.1.1
  dataclass_annotation: 0.1.1
```

### 2. 更新版本号

#### 方法一：使用 --update 参数

```bash
dart tools/update_version.dart --update 1.0.0
```

#### 方法二：直接指定版本号

```bash
dart tools/update_version.dart 1.0.0
```

**输出示例：**
```
开始更新版本号到: 1.0.0
==================================================
更新包: data_class_gen
✓ 更新 pubspec.yaml 版本号为: 1.0.0
更新包: dataclass_annotation
✓ 更新 annotation/pubspec.yaml 版本号为: 1.0.0
✓ 更新 version.yaml 版本号为: 1.0.0
==================================================
✅ 所有包的版本号已成功更新到: 1.0.0
```

### 3. 显示帮助信息

```bash
dart tools/update_version.dart --help
```

或使用简写：

```bash
dart tools/update_version.dart -h
```

## 版本号规范

本项目遵循[语义化版本](https://semver.org/lang/zh-CN/)规范：

- **主版本号**：当你做了不兼容的 API 修改
- **次版本号**：当你做了向下兼容的功能性新增
- **修订号**：当你做了向下兼容的问题修正

**有效的版本号格式：**
- `1.0.0`
- `2.1.0`
- `1.0.0-alpha.1`
- `2.0.0-beta.2`
- `1.0.0+20230101`

**无效的版本号格式：**
- `1.0` （缺少修订号）
- `v1.0.0` （不应包含前缀）
- `1.0.0.1` （过多的版本号段）

## 工作流程建议

### 开发阶段

1. **功能开发**：使用开发版本号（如 `0.1.0-dev.1`）
2. **测试阶段**：使用预发布版本号（如 `0.1.0-alpha.1`、`0.1.0-beta.1`）
3. **发布准备**：使用候选版本号（如 `0.1.0-rc.1`）
4. **正式发布**：使用正式版本号（如 `0.1.0`）

### 发布流程

1. **更新版本号**：
   ```bash
   dart tools/update_version.dart 1.0.0
   ```

2. **验证版本同步**：
   ```bash
   dart tools/update_version.dart --show
   ```

3. **更新CHANGELOG**：手动更新各包的CHANGELOG.md文件

4. **发布annotation包**：
   ```bash
   cd annotation
   dart pub publish --dry-run
   dart pub publish
   ```

5. **更新主包依赖**：将主包pubspec.yaml中的annotation依赖改为pub版本

6. **发布主包**：
   ```bash
   dart pub publish --dry-run
   dart pub publish
   ```

## 故障排除

### 常见错误

1. **版本号格式错误**
   ```
   ❌ 错误: 无效的版本号格式: 1.0（应使用语义化版本，如: 1.0.0）
   ```
   **解决方案**：使用正确的语义化版本格式

2. **配置文件不存在**
   ```
   ❌ 更新版本号失败: 版本配置文件 version.yaml 不存在
   ```
   **解决方案**：确保项目根目录存在version.yaml文件

3. **pubspec.yaml文件不存在**
   ```
   ❌ 更新版本号失败: pubspec.yaml文件不存在: annotation/pubspec.yaml
   ```
   **解决方案**：检查配置文件中的路径是否正确

### 手动修复

如果自动更新失败，可以手动修复：

1. **检查version.yaml格式**：确保YAML格式正确
2. **检查文件路径**：确保所有路径都存在
3. **手动更新版本号**：直接编辑pubspec.yaml文件
4. **重新运行脚本**：修复问题后重新运行

## 扩展功能

### 添加新包

要将新包添加到版本管理系统：

1. 在`version.yaml`的`packages`部分添加新包配置：
   ```yaml
   packages:
     new_package:
       path: "path/to/new/package"
       pubspec: "pubspec.yaml"
   ```

2. 运行版本更新脚本验证配置：
   ```bash
   dart tools/update_version.dart --show
   ```

### 自定义配置

可以根据项目需要修改`version.yaml`中的配置，脚本会自动适应新的配置结构。

## 注意事项

1. **备份重要文件**：在批量更新版本号前，建议备份重要文件
2. **检查依赖关系**：确保包之间的依赖关系正确
3. **测试验证**：更新版本号后运行测试确保功能正常
4. **Git提交**：及时提交版本更新的变更

## 技术实现

版本管理脚本使用Dart编写，主要功能包括：

- **YAML解析**：自定义YAML解析器处理配置文件
- **文件操作**：读取和写入pubspec.yaml文件
- **版本验证**：验证语义化版本格式
- **批量更新**：同时更新多个包的版本号
- **状态显示**：显示当前版本状态和更新结果

脚本设计为轻量级和独立的，不依赖外部包，可以在任何Dart环境中运行。