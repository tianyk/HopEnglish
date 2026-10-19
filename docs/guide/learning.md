# 学习引擎、课程计划与重试编排

算法业务口径统一在 [学习算法 v2](../learning_algorithm_v2.md)，本指南负责说明实现归属、输入边界、兼容路径和验证方式，不另维护一套间隔常量。

## 1. 各对象的责任

| 对象 | 入口/输出 | 不承担 |
|---|---|---|
| `LearningCandidate` | 词 ID、阶段、复习时间、上次结果、曝光/兴趣事实 | Flutter Word/Category、数据库查询 |
| `LearningPlanInput` | 候选、requestedSize、nowMs、lessonId、seed、排除集合 | 系统时间获取、读取设置 |
| `LearningEngine.createPlan` | SelectedLearningItem 列表与 policyVersion | 词图片、题目 UI、数据库写入 |
| `LessonSessionService` | 查库、转换候选、映射 Word、打乱问题、生成选项 | 另算长期掌握与复习间隔 |
| `LessonQuizController` | 维护本课问题副本、插入重试和补间隔强化题 | 长期阶段落库、页面动画 |
| `LearningEngine.applyAttempt` | 纯输入到 LearningTransition | 认为数据库已保存 |
| `LearningProgressService` | 计算转换、等待 DAO 保存，再返回 | 持有路由或 BuildContext |

纯引擎可以依赖纯 Dart 输入模型；不把 Flutter `Color` 或 Category 传入引擎。

## 2. 复现边界

使用现有 `buildLessonFromProgress` 注入相同 `nowMs`、`randomSeed`、`lessonId`、进度和分类，可以在同一支持环境复现课程；引擎验证直接构造 `LearningPlanInput`。

- 不在纯引擎内部调用 `DateTime.now()` 或无 seed 的 `Random()`。
- `LessonSessionService.buildLesson` 当前由系统时间和 `Object.hash(categoryId, nowMs)` 得 seed。Dart 的 Object.hash 不承诺跨进程/跨 SDK 稳定，不能只记录时间就宣称跨环境复现。
- `LessonPlan` 已携带 seed/版本/身份，但当前没有完整课程快照持久化；进程退出后的精确恢复尚未实现。
- 不因新测试难以构造状态就修改算法默认值；先使用已有可控输入入口。

## 3. 计划与显示分离

初始计划决定选中词、studyWords 和初始题目。学习阶段与测验阶段消费同一计划，不能每次 build/点 Next 都重新选词。

错误重试增加队列长度，属于有明确规则的课内变化；当前进度条在页面内保持不回退，不能据此推导固定总题数。空题目、少于四个候选、尾部重试补题等边界必须结合页面支持范围判断，不只证明引擎返回了列表。

当前题的 stage/reviewLevel 是计划快照。重复写入、恢复和同课多入口若涉及最新状态，必须核对数据库及调用边界；`last_quiz_lesson_id` 字段或 engine 的单次判断不能独自证明全链路幂等。

## 4. 三条容易混淆的历史路径

| 路径 | 当前事实 | 维护约定 |
|---|---|---|
| 默认 v2 | Registry 默认 2，主开课调用 engine | 新课程以此为默认 |
| `LEARNING_POLICY_VERSION=1` | engine 的 `_createLegacyPlan` 按测验时间、连续正确等生成计划 | 有兼容测试，仍保留 |
| 旧曝光分桶 | `AdaptiveSortingService` + LearningMode/WordBucket | 文件存在，当前未找到主流程调用；不是 Registry v1 的实际实现 |

此外 `LessonPlan()` 的默认 `lessonId='legacy'`、`policyVersion=1` 会命中页面特殊写入路径。UI 测试使用默认值只能保护该路径的现状，不能外推为生产 v2 保存行为。

## 5. 修改学习规则的步骤

1. 从已确认业务规则得到预期，写清当前输入与应发生的结果；规则不明确时先记录差异。
2. 在纯引擎/策略修改决策，课程服务只做映射；若改变持久态，按 [持久化指南](persistence.md) 加迁移。
3. 核对初始选项、错误重试、补间隔题、同课作答和 More 的调用结果，避免只有 engine 用例通过。
4. 使用固定时点/seed、独立边界样例和适用真实 SQLite 验证；更新业务来源与 [实施状态](../product_status.md)。

## 6. 交付证据

算法测试证明计算契约，课程服务测试证明 Word/题目映射，页面测试证明交互时序，数据库检查证明持久化。分别标明实际覆盖的策略和入口，不用“学习测试全部通过”概括未覆盖的失败恢复、插件或恢复行为。
