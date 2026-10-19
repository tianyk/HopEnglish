# 产品实施状态与文档差异

核对日期：2026-10-18。依据当前工作区源码，包含既有未提交修改；这是代码事实与文档期望的对照，不是产品批准、真机验收或发布记录。

## 1. 当前可达能力

| 能力 | 实现位置 | 代码事实与验证范围 |
|---|---|---|
| 分类首页 | `lib/src/pages/home_page.dart` | 加载 12 个分类，点分类生成本课，保留词库与设置入口 |
| 图音学习 → 听音选图 → 庆祝 | `word_learning_page.dart`、`celebration_page.dart` | 当前主线；原 PRD 的浏览整分类后自动返回不是现行实现 |
| 课词数 | `app_settings_service.dart`、`lesson_settings_sheet.dart` | 目标 5/6/8，默认 6；实际新课可因新词上限短于目标 |
| 学习决策 | `lib/src/learning/`、`lesson_session_service.dart` | 默认 v2、版本与 seed；有纯决策/计划测试 |
| 错误重试 | `lesson_quiz_controller.dart` | 显式插入二选一及必要间隔题；有队列/页面测试 |
| 进度持久化 | `app_database.dart`、`learning_progress_dao.dart` | SQLite v3，关键作答使用事务；FFI 用例覆盖部分迁移和写入 |
| 正常/慢速与鼓励语音 | `audio_playback_service.dart` | 随包 WAV，页面等待顺序有替身测试；真实插件未在本次验收 |
| 自由点读 | `word_library_page.dart` 中两个页面 | 按分类选词、单词播放；不负责课程测验 |
| 完成出口 | `WordLearningPage._openCelebration` | Home 回根；More 当前仍留同分类，排除上一组作为选词输入 |

表中短文件名位于 `lib/src/pages/`、`services/` 或 `data/`。目录和接口索引见 [架构指南](guide/architecture.md)。

## 2. 已发现但本轮未修复的实现缺口

| 编号 | 代码事实 | 应满足的约束/后果 | 依据及后续验证 |
|---|---|---|---|
| E-01 | Home 开课用 try/finally，无 catch；分类加载错误只有文字 | 失败恢复入口不完整，未处理异常不能冒充成功 | `HomePage._startLesson/_buildCategoryGrid`；需失败注入 |
| E-02 | More 在 await 回调后才解除 loading，无 finally | 回调抛错可留下 Home/More 都被锁定的状态 | `CelebrationPage._buildActions`；需异常后重试验证 |
| E-03 | `_recordAttempt` 捕获失败后返回 null，页面留题无明确反馈 | 不误完成已有基础，但恢复提示不完整 | `WordLearningPage._recordAttempt/_selectAnswer`；需关键保存延迟/失败验证 |
| E-04 | 曝光 Timer 只检查 mounted、token、阶段，未观察 AppLifecycle | 前后台计数与音频交接未形成显式契约 | 当前 `lib/` 引用搜索及学习页；需设备/生命周期测试 |
| E-05 | 播放 token 仅属于单个 AudioPlaybackService | 跨页多实例单人声不能由此证明 | 学习、探索、庆祝页面的实例创建与 dispose；需竞争/设备验证 |
| E-06 | 部分 UI 测试使用默认 legacy Plan，辅助进度单例写入失败被吞 | 页面用例通过不能证明 v2 全部数据已保存 | `test/word_learning_page_test.dart`；初次检查的错误日志见优化规划 §2 |
| E-07 | 音频服务测试只断言权重 | 缺少真实服务中断/完成/超时保护 | `test/audio_playback_service_test.dart`；按音频指南选取验证 |
| E-08 | 数据库测试设置 FFI，但直接使用默认 getDatabasesPath | 需要显式核对/建立隔离目录，关闭连接不等于隔离 | `test/database_migration_test.dart`、`databasePathForTesting` |
| E-09 | 关键 DAO 更新没有答题事件去重条件；engine 判断基于传入快照 | 原子写入不等于重复/并发作答幂等 | `recordLearningAttempt`、`applyAttempt`；需重复写入回读 |
| E-10 | 测试验证迁移部分字段，未对比全部索引/DDL | 不得宣称新装与所有旧版本升级完全等价 | 新装三个索引、升级步骤与 FFI fixture；需结构比较 |
| E-11 | seed 由 Object.hash 派生，计划未完整持久化 | 当前支持固定输入复现，不是跨进程精确恢复 | `LessonSessionService._seedFor/buildLessonFromProgress` |
| E-12 | AdaptiveImage 的 SVG 分支无普通图同等 errorBuilder | 不能承诺所有资源错误都有自定义回退 | `AdaptiveImage.build`；按实际格式验证 |

以上是静态代码事实及有依据的后果判断；本轮未修改业务代码，也未做这些场景的故障注入或真机复现。

## 3. 产品目标与待核对项

| 主题 | 文档期望 | 当前事实 | 状态与处理 |
|---|---|---|---|
| 首页去分类 | Let's Play 自动轮换分类，完成后推进 | 首页仍分类网格，More 仍同分类 | 专项 PRD 待实施，保留需求；不在工程规范维护中顺带开发 |
| 屏幕方向 | 历史 PRD/设计文档写横屏 | main 请求竖屏；Info.plist 声明多个方向 | 历史描述失配，后续涉及方向时核对产品决策，不自动恢复横屏 |
| iPad | 旧 README 写支持 iPhone/iPad | Runner 目标配置的 device family 为 1；项目级配置有 1,2 | 当前目标为 iPhone；iPad 支持需另行决定并验证 |
| 30 分钟会话恢复 | PRD 原有规则 | 无恢复快照与明确前后台时限逻辑 | 需求存在，未实现；不写成现行能力 |
| 15 分钟休息/家长锁 | 历史 PRD 有描述 | 当前没有对应可达流程 | 待产品排期，不因常量存在判为已完成 |
| 网络内容 | 模型 getter 支持 URL | 随包配置为本地；远程 slow 分支不完整 | 不能宣称完整动态内容能力；隐私/离线说明以实际发布包为准 |
| 旧曝光分桶 | 旧进度文档把它当 Registry v1 | 主开课未调用 AdaptiveSortingService；engine v1 为另一套测验兼容逻辑 | 已校正文档，代码保留用途待核对 |

## 4. 工程文档与基础设施状态

根规范、专项指南、文档索引、四层记忆文件和项目验证/流程审查技能本轮已建立；它们定义后续工作的入口，不证明 E-01～E-12 已修复。

2026-10-19 仅更新 Agent 指导：任务模式与完成条件、按需读取、文档可信度、事实纠错边界，以及两份技能的输入／分支／阻塞处理。完成范围见 [优化规划 §9](engineering_optimization_plan.md)，不刷新上文应用事实的核对日期。

SDK 固定、统一应用验证脚本、CI、业务重构与发布链路实测尚未完成。native assets 脚本属于本轮之前的在途改动，本轮只核对并编写使用说明。

## 5. 维护规则

新证据关闭差异时更新对应条目、日期和实际验证范围，不只删除问题。产品规则的改变回写专项业务来源；历史记录留在 Daily，不在本文件累计每次工具过程。
