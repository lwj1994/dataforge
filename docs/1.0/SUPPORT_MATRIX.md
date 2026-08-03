# Dataforge 1.0 支持矩阵

实现状态：`1.0.0-dev.0` 预览，尚未达到 1.0 GA。

本文只描述 v1 `abstract final` 值对象链路。表中的“目标”表示正式 1.0 必须交付，
“预览”表示当前已有实现但 API/输出仍可能变化。

相关文档：[1.0 RFC](RFC.md)

## 1. 前端与生成

| 能力 | build_runner | CLI | 当前状态 |
| --- | ---: | ---: | --- |
| Resolved Analyzer library | 是 | 是 | 预览 |
| 注解常量求值 | 是 | 是 | 预览 |
| Import prefix、re-export、typedef | 是 | 是 | 预览 |
| Library part 归并到 defining library | 是 | 是 | 预览 |
| 同名非 Dataforge annotation 不误判 | 是 | 是 | 预览 |
| 共享 resolved schema/renderer | 是 | 是 | 预览 |
| 代表性 fixture 字节一致 | 是 | 是 | 已验证 |
| 完整类型矩阵字节一致 | 目标 | 目标 | 未完成 |
| 直接构造 raw schema / 调用 renderer | 否 | 否 | 不支持，内部 API |
| 修改模型源码 | 否 | 否 | 不支持 |

annotation import 使用 `show`/`hide` 时，生成 part 所需 runtime API 必须在一个可见
namespace/prefix 中完整存在；否则应增加完整的 prefixed import。

## 2. 模型声明

| 声明 | 状态 | 说明 |
| --- | --- | --- |
| `abstract final class` | 预览 | v1 唯一公开模型形状 |
| unnamed redirecting factory | 预览 | 参数定义全部值属性 |
| 生成 `final` implementation | 预览 | 唯一受支持 concrete value type |
| `const Model._()` | 预览 | 供生成实现调用的私有基类构造器 |
| `@Dataforge(name: ...)` | 预览 | 修改 private implementation 基名 |
| `@DataforgeDefault(value)` | 预览 | resolved 常量与可赋值性校验 |
| `@JsonKey` name/alternateNames/ignore/includeIfNull | 预览 | const metadata |
| 多个/有界泛型参数 | 预览 | 依赖参数语义时必须提供 witness |
| 公开 const redirecting factory | 不支持 | 与外部集合防御复制冲突 |
| 用户 subtype/implementation/generated helper | 不支持 | 破坏唯一 final implementation 边界 |
| 额外 named constructor、继承、implements | 不支持 | 生成期 diagnostic |

## 3. 类型、冻结与 JSON

| 类型 | Freeze / equality / hash | 默认 JSON | 当前状态 |
| --- | --- | --- | --- |
| null、bool、int、double、num、String | 值语义 | JSON scalar | 预览 |
| enum | enum 值语义 | 严格名称 codec | 预览 |
| DateTime | 不可变；按同一时刻 | 输入需 offset，输出 UTC `Z` | 预览 |
| Duration | 不可变；Dart 值语义 | microseconds int | 预览 |
| Uri、BigInt | exact witness | witness 定义 | 显式 |
| List<T> | 递归复制；有序比较 | array | 预览 |
| Set<T> | 递归复制；无序比较 | array | 预览 |
| Map<String, V> | 递归复制；顺序无关 | object | 预览 |
| Map<K, V>，K 为 bool/int/double/num/enum/DateTime/Duration | 递归 witness 语义 | 内建唯一 String key codec | 预览 |
| Map<K, V>，K 为集合/model/custom | 递归 witness 语义 | exact witness codec 必须唯一输出 String | 显式 |
| 嵌套 Dataforge 模型 | 共享已冻结实例；递归值语义 | nested object | 预览 |
| 泛型 T | `DataforgeType<T>` 定义 | witness 定义 | 显式 |
| 自定义值 | exact witness | witness 定义 | 显式 |
| Record | 递归 positional/named 值语义 | 无默认表示 | 非 JSON；exact witness 可覆盖 |
| Object? / dynamic | 无法静态证明 | 无 | 仅 exact witness |
| Function、Future、Stream、handle | 无稳定值语义 | 无 | 不支持 |
| 循环对象图 | 无 | 无 | 不支持 |

所有集合 getter 都不可修改。冻结后在 witness equality 下重复的 Set 元素或 Map key
会报错，不会静默丢失。`toJson` 返回的新容器不与模型内部容器共享可变状态。

## 4. Strict JSON

| 场景 | 行为 | 当前状态 |
| --- | --- | --- |
| `Map<String, Object?>` 输入 | 接受 | 预览 |
| String ↔ number/bool 隐式转换 | 拒绝 | 预览 |
| int → double | 精确转换 | 预览 |
| NaN / Infinity | 拒绝 JSON | 预览 |
| required key 缺失 | `DFJ` + JSONPath | 预览 |
| required nullable key 缺失 | 错误 | 预览 |
| 默认值且 key 缺失 | 使用冻结后的默认值 | 预览 |
| 默认值但显式值非法 | 错误，不回退 | 预览 |
| unknown key | 默认拒绝 | 预览 |
| 主 key 与 alternate 同时存在 | 歧义错误 | 预览 |
| `includeIfNull: false` | 只影响 encode | 预览 |
| 循环 List/Map 输入 | DFJ1008 | 预览 |
| Set 元素解码后按 witness 重复 | DFJ1009 + 元素 JSONPath | 预览 |
| 重复原始/解码后 Map key | 拒绝 | 预览 |
| exact witness codec | 严格验证输入/输出契约 | 预览 |

错误携带稳定 code、path、expected/actual type、canonical model 和 schema field。

## 5. Equality、hash 与结构共享

| 能力 | 当前状态 | 验收要求 |
| --- | --- | --- |
| List 有序深相等 | 预览 | 顺序不同不相等 |
| Set 无序深相等 | 预览 | 插入顺序不影响 equality/hash |
| Map 深相等 | 预览 | 插入顺序不影响 equality/hash |
| nested model | 预览 | 递归 companion witness |
| 完整类型树 | 预览 | 每层容器/模型均递归到叶 witness |
| 泛型 witness compatibility | 预览 | 内置/生成 witness 比较完整 identity tree |
| 协变完整树 equality | 预览 | 内置/生成 witness 使用 erased equality protocol |
| 自定义 witness | 预览 | 默认对象 identity；可实现稳定 identity tree |
| NaN 模型值语义 | 预览 | equality/hash 一致；JSON 仍拒绝 |
| `copyWith()` 无变化返回 this | 预览 | identity 测试 |
| 未变化子树共享 | 预览 | identity 测试 |
| 外部 replacement 直接共享 | 不支持 | 必须先递归冻结 |

## 6. CLI 行为

| 能力 | 改源码 | 改生成文件 | 当前状态 |
| --- | ---: | ---: | --- |
| `dataforge generate [path]` | 否 | 是 | 预览 |
| `dataforge check [path]` | 否 | 否 | 预览 |
| 内存 resolve/render/format | 否 | 否 | 预览 |
| Analyzer overlay 编译验证 | 否 | 否 | 预览 |
| 输入快照锁内复验 | 否 | 否 | 预览 |
| 同目录原子替换 | 否 | 是 | 预览 |
| 多文件 journal rollback/recovery | 否 | 是 | 预览 |
| 未知内容/symlink/非法 journal 保留现场 | 否 | 否 | 预览 |
| 多文件 OS 同时可见 | 否 | 否 | 不承诺 |
| 结构化 generate JSON report | 否 | 否 | 未实现 |

`check` 严格只读：不创建 lock，不恢复 journal。输出漂移或存在待恢复 journal 时退出 4。

稳定退出码目标：0 成功、2 参数/配置、3 resolve/模型/生成、4 check/precondition、
5 I/O/事务、70 内部错误、130 中断。

## 7. 扫描与项目拓扑

| 场景 | 当前状态 | 规则 |
| --- | --- | --- |
| 单 Dart 文件 | 预览 | 必须属于可 resolve package |
| 目录递归 | 预览 | 确定性排序，无任意深度上限 |
| 普通业务目录名 | 预览 | 不按 basename 任意跳过 |
| `.dart_tool`、VCS、明确输出目录 | 预览 | 项目级排除 |
| Symlink directory | 预览 | 默认不跟随 |
| monorepo / nested package | 预览 | 使用最近 package config/context |
| part 作为输入 | 预览 | 归并到 defining library |
| 无 annotation library | 预览 | 成功 no-op |
| 无法读取/resolve 的候选 | 预览 | 非零 diagnostic，不静默跳过 |

## 8. 工具链与发布门禁

| 维度 | 当前门禁 | GA 仍需完成 |
| --- | --- | --- |
| Dart SDK | 3.9.0 与 stable | 后续支持窗口确认 |
| Linux | analyze/test/example | 完整类型与故障注入 |
| macOS | package tests | example 与文件系统故障注入 |
| Windows | package tests | example、锁/rename/路径故障注入 |
| build_runner / CLI parity | 代表性 fixture | 完整支持类型矩阵 |
| 深度不可变 | mutation tests | 更完整属性/模糊测试 |
| publish archive | 四包 dry-run | hosted clean-consumer 发布验证 |

在上述 GA 列全部完成前，文档和发布说明必须继续标记为 preview，不得宣称 1.0 正式
稳定或完整跨平台一致。
