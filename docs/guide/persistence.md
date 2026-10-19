# SQLite、DAO 与进度写入

字段、版本与计数的唯一来源是 [学习进度数据](../learning_progress_vnext.md)。本指南约束写入边界、事务、迁移实施与真实数据库验证。

## 1. 现有接口与返回语义

| 入口 | 返回语义 | 失败边界 |
|---|---|---|
| `AppDatabase.getDatabase/ping` | 开库或探测完成 | 底层抛错；进度服务 ping 会记录并降级 |
| `LearningProgressDao.getWordProgressByCategory` | wordKey → 数据行的 Map | 不返回伪造空数据掩盖错误 |
| `incrementView/incrementPlay` | DAO 写入完成 | 服务层辅助入口会 catch 并记日志 |
| `LearningProgressService.recordLearningAttempt` | 对应转换已落库后返回 transition | 非 legacy 关键路径向调用方抛错 |
| `LearningProgressDao.recordLearningAttempt` | 创建行与更新多个字段位于同一事务 | 异常回滚，不返回部分成功 |
| `AppSettingsService.setLessonWordCount` | 设置已持久化 | 参数错误或写入失败会抛出 |

服务的概述注释里仍有“所有写入静默失败”的历史表述，不适用于关键作答；实际区别以上述方法实现及本指南为准。

## 2. 稳定标识与模型映射

- `word_key = categoryId:wordId` 是学习项身份，不是英文拼写。移动分类、重命名 ID 会影响历史进度，必须有任务内的映射或兼容方案。
- `WordProgress.fromRow` 当前位于 `models/word_bucket.dart`，将 snake_case 行转换为领域字段；纯引擎只消费 LearningCandidate。
- `mastery_stage` 当前使用枚举 index 持久化。调整枚举顺序属于数据变更，不能当作普通重命名；新增/未知值的转换需核对旧库行为。
- 不在页面解析 raw SQL 行，不把 DAO 的 Map 长期向上扩散为无类型业务对象。

## 3. 原子写入与重复操作

- 参数化 SQL，值不拼接进语句；计数用 SQL 原子自增，避免先读再写。
- 关键转换关联的计数、阶段、时间和课程身份在同一事务保存；事务内统一使用 `txn`，不能回到外层 db 形成混用。
- 保存成功是课程推进的前置条件；失败保留可重试状态，不伪造 transition 已保存。
- 当前 DAO 没有唯一“答题事件”表或去重条件，页面锁和 `last_quiz_lesson_id` 不足以证明多次入口/恢复/并发写入幂等。
- 需要承诺幂等时，构造重复操作并回读最终计数、状态和时间；新增防护应覆盖全部副作用，而不只是按钮禁用。

## 4. 迁移实施

1. 对照当前 `_schemaVersion`、新装 DDL、已发布升级步骤、WordProgress 映射与使用字段。
2. 追加新的版本分支，更新新装结构与必要索引；已发布迁移不原地改写。
3. 在隔离 SQLite 分别验证新装、所有支持的旧版本升级、当前版本重复打开；比较字段、索引、设置和代表性历史数据。
4. 涉及回填时用独立样例核算结果，检查 NULL/默认值、未知枚举和时间单位；只“能打开库”不足以证明迁移正确。
5. 更新数据文档和验证说明；不能以删库、清空统计或回滚 schema 解决升级失败。

sqflite 的 onCreate/onUpgrade 已有事务语义，避免在其回调中机械嵌套事务。当前 v1 测试 fixture 未建 category_id/last_seen_at 索引，升级只补 next_review_at 索引；因此不能从已有测试推导新装与升级结构完全等价。对发布过的真实旧库仍需读取其结构，不能仅凭 fixture 断言用户旧库都缺索引。

## 5. 测试隔离

现有测试使用 `sqflite_common_ffi`，替换 `databaseFactory` 后调用生产 AppDatabase/DAO。默认路径通过 getDatabasesPath 取得，不是硬编码真机目录。

- 执行前确认 FFI 测试路径是测试创建的隔离目录；不要直接复用用户数据路径。
- 新增或改动该类测试时，优先使用临时目录，并恢复全局 factory/path；避免同路径并行用例互相删除。
- `closeForTesting` 只关闭缓存连接；`databasePathForTesting` 不自动保证路径已隔离。
- 保存最终值、历史数据保留与约束结果作为证据；mock 数据库、匹配 SQL 字符串和服务 catchError 后全绿都不能证明落库。

## 6. 待修复项的归属

当前测试路径隔离、幂等和页面保存恢复的具体差异见 [实施状态](../product_status.md)。本指南规定后续修改的标准，不将未完成的防护写成已具备能力。
