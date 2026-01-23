# 循环依赖问题说明

## 什么是循环依赖？

循环依赖（Circular Dependency）是指两个或多个类相互引用，形成一个环状结构。

## 问题示例

### 场景 1：简单循环（User ↔ Post）

```dart
@Dataforge()
class User {
  final String name;
  final Post? favoritePost;  // User 引用 Post

  User({required this.name, this.favoritePost});
}

@Dataforge()
class Post {
  final String title;
  final User author;  // Post 引用 User

  Post({required this.title, required this.author});
}
```

### 当前会生成什么代码？

```dart
// user.data.dart
class _$User with _$UserMixin {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      favoritePost: (json['favoritePost'] != null
        ? Post.fromJson(json['favoritePost'])  // ✅ 调用 Post.fromJson
        : null),
    );
  }
}

// post.data.dart
class _$Post with _$PostMixin {
  static Post fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title'],
      author: User.fromJson(json['author']),  // ✅ 调用 User.fromJson
    );
  }
}
```

## 潜在问题

### 1️⃣ **代码生成顺序问题**

如果 Dataforge 先生成 `user.data.dart`，此时它会引用 `Post.fromJson`，但如果 `post.data.dart` 还未生成，**编译可能失败**。

```
Error: Method not found: 'Post.fromJson'
```

### 2️⃣ **JSON 反序列化可能无限递归**

如果 JSON 数据包含循环引用：

```json
{
  "name": "Alice",
  "favoritePost": {
    "title": "My Post",
    "author": {
      "name": "Alice",
      "favoritePost": {
        "title": "My Post",
        "author": { ... }  // 无限循环！
      }
    }
  }
}
```

调用 `User.fromJson(json)` 会导致：
```
User.fromJson → Post.fromJson → User.fromJson → Post.fromJson → ...
```

**结果：栈溢出（Stack Overflow）！**

### 3️⃣ **copyWith 链式调用可能出错**

```dart
user.copyWith(
  favoritePost: user.favoritePost?.copyWith(
    author: user.favoritePost?.author.copyWith(  // 访问自己？
      name: 'New Name',
    ),
  ),
)
```

逻辑上可能陷入循环引用。

## 实际案例场景

### 案例 1：社交网络
```dart
@Dataforge()
class User {
  final String name;
  final List<User> friends;  // User 引用自己！
}
```

### 案例 2：树形结构
```dart
@Dataforge()
class TreeNode {
  final String value;
  final TreeNode? parent;
  final List<TreeNode> children;
}
```

### 案例 3：多层循环
```dart
@Dataforge()
class Company {
  final List<Employee> employees;
}

@Dataforge()
class Employee {
  final Department department;
}

@Dataforge()
class Department {
  final Company company;  // 形成环：Company → Employee → Department → Company
}
```

## 当前 Dataforge 的行为

根据代码审查，**Dataforge 目前没有循环依赖检测**：

- ✅ 生成的代码在语法上是正确的
- ⚠️ **不会警告用户存在循环依赖**
- ⚠️ **不会检测无限递归风险**
- ❌ 如果 JSON 数据包含循环引用，运行时会崩溃

## 应该如何处理？

### 方案 1：检测并警告（推荐）

在解析阶段检测循环依赖，给出警告：

```
⚠️  Warning: Circular dependency detected:
    User → Post → User

    This may cause issues if your JSON data contains circular references.
    Consider using @JsonKey(ignore: true) on one side of the relationship.
```

### 方案 2：禁止循环依赖

直接报错，强制用户修改设计：

```
❌ Error: Circular dependency detected: User ↔ Post
   Please break the cycle by:
   1. Making one field nullable with @JsonKey(ignore: true)
   2. Using a different serialization strategy
```

### 方案 3：支持循环引用（复杂）

在 `fromJson` 中添加访问过的对象缓存：

```dart
static User fromJson(Map<String, dynamic> json, [Set<int>? visited]) {
  final id = json.hashCode;
  if (visited?.contains(id) == true) {
    throw CircularReferenceException('Circular reference detected');
  }
  visited = (visited ?? {})..add(id);
  // ... 继续反序列化
}
```

## 建议的修复

### 在 Parser 中添加检测

```dart
// dataforge_base/lib/src/parser.dart

class CircularDependencyDetector {
  final Map<String, Set<String>> _dependencies = {};

  void addDependency(String className, String dependsOn) {
    _dependencies.putIfAbsent(className, () => {}).add(dependsOn);
  }

  List<List<String>> detectCycles() {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final stack = <String>[];

    void dfs(String node) {
      if (stack.contains(node)) {
        // 找到循环
        final cycleStart = stack.indexOf(node);
        cycles.add(stack.sublist(cycleStart)..add(node));
        return;
      }

      if (visited.contains(node)) return;

      visited.add(node);
      stack.add(node);

      for (final dep in _dependencies[node] ?? {}) {
        dfs(dep);
      }

      stack.removeLast();
    }

    for (final node in _dependencies.keys) {
      dfs(node);
    }

    return cycles;
  }
}
```

### 使用建议

如果检测到循环依赖，建议用户：

```dart
@Dataforge()
class User {
  final String name;

  @JsonKey(ignore: true)  // ✅ 忽略此字段
  final Post? favoritePost;

  User({required this.name, this.favoritePost});
}

@Dataforge()
class Post {
  final String title;
  final User author;  // 保留这边

  Post({required this.title, required this.author});
}
```

或者使用 ID 引用：

```dart
@Dataforge()
class User {
  final String id;
  final String name;
  final String? favoritePostId;  // ✅ 只存 ID，不存对象
}

@Dataforge()
class Post {
  final String id;
  final String title;
  final String authorId;  // ✅ 只存 ID
}
```

## 总结

循环依赖问题是代码生成框架需要注意的重要问题：

- **当前状态**：Dataforge 不检测循环依赖
- **风险等级**：高 - 可能导致运行时崩溃
- **影响范围**：任何包含相互引用的数据模型
- **建议修复**：添加循环依赖检测，至少给出警告

**建议优先级：高 ⚠️**
