# 项目结构与真实入口

状态：现行目录说明，2026-10-18 按工作区核对。工程约束归 [架构指南](guide/architecture.md)，能力与缺口归 [实施状态](product_status.md)。

## 1. 目录快照

```text
lib/
  main.dart
  src/
    constants/app_strings.dart
    data/{app_database,learning_progress_dao}.dart
    learning/{learning_engine,learning_policy,learning_models}.dart
    libs/{logger,utils}.dart
    models/{category,word,lesson_plan,word_bucket,learning_mode,models}.dart
    pages/{home_page,word_learning_page,celebration_page,word_library_page}.dart
    services/
      category_service.dart
      lesson_session_service.dart
      lesson_quiz_controller.dart
      learning_progress_service.dart
      audio_playback_service.dart
      app_settings_service.dart
      adaptive_sorting_service.dart
    theme/app_theme.dart
    widgets/
      adaptive_image.dart
      word_icon.dart
      category_card.dart
      lesson_settings_sheet.dart
      word_directory_sheet.dart
assets/{data,images,audio,fonts}/
scripts/{dreamina-word-generator,tts-generator}/
ios/
test/
docs/guide/
.agents/skills/
.memory/
```

花括号是列表简写。分类内容来自 `assets/data/categories.json`，当前不存在 `lib/src/config/category_config.dart` 或 `lib/core/`。

## 2. 主流程

| 入口/步骤 | 当前实现 |
|---|---|
| 初始化 | main 请求竖屏、启动应用、异步预热进度数据库 |
| 全局文本策略 | AppTextScaleBoundary 固定文字缩放 |
| 首页 | HomePage 读分类和设置，按分类生成课程 |
| 计划 | LessonSessionService 读取进度并调用纯 LearningEngine |
| 学习与测验 | WordLearningPage 消费 LessonPlan，LessonQuizController 插入错误重试 |
| 作答 | LearningProgressService 计算 transition，DAO 事务保存 |
| 完成 | CelebrationPage，Home 返回首页，More 构造同分类后续课 |
| 词库与探索 | `word_library_page.dart` 同时定义 WordLibraryPage 和 WordExplorePage |

当前学习页需要 `plan` 和 `lessonSize`；`WordLearningPage(category: ..., initialIndex: ...)` 是旧接口，不能继续复制。

## 3. 历史保留与复用边界

- `AdaptiveSortingService` 使用旧曝光/兴趣分桶，当前未找到主流程调用。
- `WordDirectorySheet` 保留旧目录 UI，当前未找到生产入口。
- Registry v1 是 LearningEngine 内的测验兼容策略，与旧曝光分桶不同。
- `WordProgress` 位于 `word_bucket.dart`，仍被当前课程主线使用，不能连同旧桶逻辑直接删除。
- 图片显示复用 AdaptiveImage/WordIcon；其他共用交互现状见 [组件清单](guide/components.md)。

## 4. 放置新代码

根据职责沿用现有目录，不另建第二套 services/repositories/core 体系。页面专属部分先留在页面附近；SQL 进 data；纯学习决策进 learning；工具依赖留在所属 scripts 项目。

新增或迁移模块时核对导出、生产调用、测试、资源和文档引用。源码目录表说明当前事实，新增规则统一维护在根规范及 guide，避免两份互相冲突的命名和行数限制。
