# 学习进度数据与 SQLite Schema

状态：现行数据说明，2026-10-18 核对，Schema v3。算法规则见 [学习算法 v2](learning_algorithm_v2.md)，写入和迁移方法见 [持久化指南](guide/persistence.md)。文件名保留历史链接，不表示本页仍是未实施 vNext。

## 1. 身份、单位与计数

学习项按 `categoryId:wordId` 标识；同形同音但不同含义（如水果/颜色 Orange）分别统计。categoryId 全局唯一，wordId 在分类内唯一；换分类或 ID 需要兼容迁移，不能只改 JSON。

所有持久化时间使用 epoch 毫秒，NULL 表示没有对应事实，不能用 0 混同“未知”。

| 指标 | 当前计数入口 | 口径和限制 |
|---|---|---|
| view_count | 学习页 `_presentLearningWord` 的有效展示 Timer | 当前延迟 1200ms，核对 token/阶段；不是旧文档建议的 300–500ms |
| play_count | 页面收到 playWord 的成功/有效结果后调用服务 | 服务按同一 wordKey 的 1000ms 窗口合并；API 的开始/完成语义见音频指南 |
| quiz_attempt_count | 当前首次提取/计划复习作答 | 正误都记一次；错误重试/强化题不作为新的长期计数 |
| quiz_correct_count | 首次作答正确 | 不把最终纠正选对当作首次正确 |
| correct_streak | 首次正确加一，首次错误归零 | 旧兼容数据，v2 掌握不能仅由此反推 |

播放/曝光是辅助信号，不等于掌握。前后台有效曝光与重复写入的防护缺口见 [实施状态](product_status.md)。

## 2. word_progress

表结构来源：`lib/src/data/app_database.dart`；领域映射：`lib/src/models/word_bucket.dart` 中 WordProgress。

| SQLite 字段 | 类型/默认 | 含义 |
|---|---|---|
| word_key | TEXT PRIMARY KEY | categoryId:wordId |
| category_id | TEXT NOT NULL | 分类身份 |
| word_id | TEXT NOT NULL | 分类内学习项身份 |
| word_name | TEXT NOT NULL | 英文名称冗余，便于调试 |
| view_count / play_count | INTEGER NOT NULL DEFAULT 0 | 有效曝光/播放计数 |
| quiz_attempt_count / quiz_correct_count | INTEGER NOT NULL DEFAULT 0 | 首次作答计数 |
| correct_streak | INTEGER NOT NULL DEFAULT 0 | 首次连续正确 |
| last_seen_at / last_played_at | INTEGER NULL | 最近有效曝光/播放 |
| last_quizzed_at / last_correct_at | INTEGER NULL | 最近作答/首次正确 |
| mastery_stage | INTEGER NOT NULL DEFAULT 0 | 枚举序号：New 0、Acquired 1、Consolidating 2、Stable 3 |
| review_level | INTEGER NOT NULL DEFAULT 0 | Stable 复习级别 |
| next_review_at | INTEGER NULL | 下次到期时间 |
| last_quiz_lesson_id | TEXT NULL | 上次记录首次作答的课身份 |
| last_quiz_result | INTEGER NULL | 首次结果，1 正确、0 错误 |
| last_policy_version | INTEGER NOT NULL DEFAULT 1 | 写入/迁移对应策略版本 |

新装路径创建 `category_id`、`last_seen_at`、`next_review_at` 三个单列索引。升级路径能否得到完全相同索引要通过实际结构验证，不能只看字段存在。

## 3. category_progress 与 app_settings

| 表 | 字段 | 含义 |
|---|---|---|
| category_progress | category_id TEXT PRIMARY KEY | 分类 |
| category_progress | last_session_at INTEGER NULL | 进入主题学习页时更新 |
| category_progress | last_exited_at INTEGER NULL | 离开学习页时更新 |
| app_settings | key TEXT PRIMARY KEY、value TEXT NOT NULL | 本地设置字符串 |

现有设置键 `lesson_word_count`，合法值 5/6/8、默认 6；无效存量值读取时回退默认，保存非法值会抛错。当前 category_progress 只存两个时间锚点，不是完整课程快照，也不是默认分类轮换游标。

## 4. 写入链与失败语义

- 开始课：记录 category session；每个学习词达到有效展示延迟后记曝光。
- 自动/手动正常/慢速播放：以页面收到的有效播放结果计数，服务合并短时间重复信号。
- 首次作答：纯引擎计算 transition，非 legacy 服务等待 DAO 将计数、阶段、间隔和课身份原子保存。
- 重试/强化：属于本课练习，不通过同样入口重复提高长期状态。
- 离开课：更新退出时间，取消展示 Timer 与其他页面资源。

辅助入口 touch/view/play/退出会捕获并记录错误；关键作答与设置保存向调用方暴露失败。legacy 页面分支仍有特殊处理，不能沿用旧“所有写入静默失败”的说明。

## 5. 迁移历史与数据保留

| Schema | 变更 | 数据口径 |
|---|---|---|
| v1 | word_progress、category_progress | 曝光/播放与时间事实 |
| v2 | 首次作答相关字段、app_settings | 老曝光数据不视为测验掌握 |
| v3 | 掌握、级别、到期、课身份、结果、策略版本与到期索引 | 保守迁移，不把旧连续正确直接提升为 Stable |

v3 回填按已执行的 SQL 解释：无测验或 streak=0 → New，streak=1 → Acquired，其他 → Consolidating；review_level=0；next_review_at 对 NULL 测验时间保留 NULL，streak=1/≥2 分别用上次测验时间加 1/3 天，否则用上次测验时间；结果依作答次数与 streak 填写，last_policy_version=1。

后续结构变化追加新版本，更新新装 DDL、升级步骤、领域映射和本页。迁移测试回查历史值与结构，不通过删除学习库恢复运行。

## 6. 旧分桶与会话描述的适用范围

旧版的 daily/review/restart、Overdue/Warm/Favorite 属于 `AdaptiveSortingService` 的曝光分桶设计，当前不是主流程，也不是 `LEARNING_POLICY_VERSION=1` 的实际 engine 路径。兼容区别见 [学习指南](guide/learning.md)。

历史 PRD 的“后台 ≤30 分钟仍为同会话”是尚未完整实现的产品要求。当前 LessonPlan 的身份和页面 State 不足以支持进程退出后的课程恢复；相关需求在实施状态中单独跟踪。

## 7. 文件位置与打开方式

AppDatabase 使用 sqflite 的 getDatabasesPath 加 `hopenglish.sqlite`，不手写系统沙盒绝对目录。首次打开触发建表/迁移，缓存连接；main 在启动应用后异步预热。

测试用 FFI 时 getDatabasesPath 的行为由测试 factory 决定。`databasePathForTesting` 只提供路径，不能自动证明隔离；新增测试需按持久化指南确认临时目录与清理范围。
