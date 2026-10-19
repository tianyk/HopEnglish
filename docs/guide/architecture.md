# 架构、职责与实现落位

适用范围：Flutter 业务代码、内容工具与跨模块修改。目录快照见 [项目结构](../project_structure.md)，根约束见 [AGENTS.md](../../AGENTS.md)。

## 1. 两条真实调用链

```text
开课：HomePage
 → LessonSessionService.buildLesson
 → LearningProgressDao.getWordProgressByCategory
 → WordProgress.fromRow → LearningCandidate
 → LearningEngine.createPlan
 → LessonPlan → WordLearningPage

作答：WordLearningPage._selectAnswer
 → LearningProgressService.recordLearningAttempt
 → LearningEngine.applyAttempt
 → LearningProgressDao.recordLearningAttempt（事务）
 → 返回 LearningTransition
 → 重试队列或后续题目 → CelebrationPage
```

音频由 `AudioPlaybackController`/`AudioPlaybackService` 承担。页面还有 legacy 特殊分支；上述主线以服务生成的非 legacy 课程为准，不能把所有入口视为等价。

## 2. 依赖与职责矩阵

| 层 | 可以承担 | 不应承担 |
|---|---|---|
| pages | 显示状态、手势、动画、路由、调用业务入口 | SQL、学习公式、直接操作 AudioPlayer |
| widgets | 展示原语与有边界的交互组合 | 全局课程调度、隐式数据库写入 |
| services | 读写编排、事实转换、播放器生命周期、设置校验 | 在多处另算掌握状态、持有 BuildContext |
| learning | 纯输入到决策、策略参数、状态转换 | Flutter、DAO、播放器、系统时钟和全局随机源 |
| data | 开库、DDL/迁移、参数化 SQL、事务、行读取 | 导航、展示文案、按 UI 回调决定业务规则 |
| models | 内容/课程数据与序列化 | 播放、路由、数据库连接 |
| theme | Token、文字样式、ThemeData | 课程和内容事实 |
| scripts | 内容生产、候选处理、任务状态 | 被应用运行时 import |

`models/category.dart` 使用 Flutter `Color` 是现有 UI 内容模型；纯学习引擎使用 `LearningCandidate` 等独立模型，不把 Category 搬进引擎。`LearningTransition` 可由 DAO 作为持久化输入消费，不意味着 DAO 重新计算策略。

## 3. 现有服务的选用

| 场景 | 已有入口 | 重要边界 |
|---|---|---|
| 读取随包词表 | `CategoryService.loadCategories()` | 从 rootBundle 读取当前 JSON |
| 生成课程 | `LessonSessionService.instance.buildLesson(...)` | 读取数据库；返回完整计划 |
| 可控输入生成课程 | `buildLessonFromProgress(...)` | 支持 nowMs/seed/lessonId；是现有复现边界 |
| 动态错误重试 | `LessonQuizController.scheduleRetry(...)` | 只管理本课队列与重试次数 |
| 有效曝光/播放 | `LearningProgressService.recordEffectiveView/recordSuccessfulPlay` | 辅助写入会自行记录错误并降级 |
| 关键作答 | `recordLearningAttempt(...)` | 异步返回 transition，写入失败会抛错 |
| 课词数设置 | `AppSettingsService.get/setLessonWordCount` | 只接受 5/6/8，默认 6 |
| 播放 | `AudioPlaybackController` | 可以注入页面；语义见音频指南 |

多数服务当前采用私有构造函数加单例，并不都有公开的依赖注入入口。测试和重构要先检查实际构造签名，不能在示例里调用不存在的 `Service(dao: ...)`。

## 4. 新增与修改顺序

1. 找可达页面、服务、纯决策、DAO 与已有验证；确认本次改变的是业务规则、编排还是 UI。
2. 算法任务先确定输入输出与业务预期；持久化任务先确定字段、稳定标识和升级路径；纯布局任务从现有组件组合开始。
3. 在对应层实现最小变化，再连接上层；不强制每个任务都新增 Model/DAO/Controller。
4. 逐个失败边界核对返回值和状态，不用成功路径的默认值掩盖异常。
5. 更新唯一文档来源、实施状态与相关验证。

## 5. 文件落位与命名

- 页面以 `_page.dart` 命名，服务以 `_service.dart`、控制器以 `_controller.dart`、DAO 以 `_dao.dart` 结尾；Dart 统一 snake_case。
- 页面专属组件可留私有类或放 `pages/<feature>/` 附近。跨页面且输入稳定才进入 `widgets/`。
- 不新增 `core/`、`common/`、`helpers/` 等第二套无明确职责目录；通用能力先查 `libs/`，具体业务能力保持领域名称。
- `WordProgress` 当前在 `models/word_bucket.dart`，调整位置需更新所有引用；文件名历史问题不授权无关大搬迁。
- 服务公开 API、关键转换和复杂状态分支补充注释；优先表达为什么需要等待、幂等、降级或保持历史状态。

## 6. 架构评审

检查规则是否只定义一次、纯引擎是否仍独立、持久化是否回查实际结果、页面是否承担过多所有权，以及抽取是否有真实调用方。仅目录分得细或类名齐全不能证明架构合格。
