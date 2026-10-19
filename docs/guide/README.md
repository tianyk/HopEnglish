# 开发指南

本目录把根规范展开为可以按任务执行的工程方法。根约束见 [AGENTS.md](../../AGENTS.md)，业务文档及维护职责见 [文档索引](../README.md)。

维护约束与事实纠错均按根规范的维护边界处理。阅读时区分应遵循的规则、推荐模式和当前实现说明；具体缺口与关闭证据统一见 [实施状态](../product_status.md)。

## 指南入口

| 指南 | 实际用途 |
|---|---|
| [architecture.md](architecture.md) | 分层、依赖方向、现有服务与 API、实现落位顺序 |
| [flutter-ui.md](flutter-ui.md) | 状态归属、加载/失败、异步、导航、依赖注入与页面验收 |
| [components.md](components.md) | 真实组件目录、现有能力限制、抽取门槛和 API 设计 |
| [learning.md](learning.md) | engine/策略/课程/重试的边界与复现方式，区别两类历史算法 |
| [persistence.md](persistence.md) | 关键写入、事务、模型映射、迁移与测试隔离 |
| [audio-lifecycle.md](audio-lifecycle.md) | 播放 API 的实际语义、所有权、时序和前后台验证 |
| [content-assets.md](content-assets.md) | 词表到资源、生成、候选、采用和内容验收 |
| [verification.md](verification.md) | 验证入口、证据范围、环境失败与发布检查 |

## 按任务的最小路径

| 任务 | 先读并确定 | 追加条件 |
|---|---|---|
| 新页面或复杂交互 | architecture、flutter-ui、components 相关章节及目标需求，确定状态归属与复用入口 | 视觉变化读设计系统；涉及持久化或播放再读对应指南 |
| 学习策略 | learning、学习算法业务文档，确定规则依据与决策边界 | 改字段或写入语义读 persistence；改变展示时序读 flutter-ui |
| 数据/迁移 | persistence、进度 Schema，确定身份、升级和写入契约 | 再核对受影响 DAO／映射／测试；仅跨到页面时读取 UI 指南 |
| 播放/切后台 | audio-lifecycle、实际调用方，确定所有权与异步身份 | 涉及页面等待、导航读 flutter-ui；涉及计数读进度文档 |
| 词表/资源/生成器 | content-assets、内容 Schema，确定身份、路径和采用边界 | 运行或修改工具时读所属 README；视觉或发音变化追加相应验收 |
| 评审/补测 | test-case-generator 技能，确定具体风险与已有保护 | 需要执行检查时读 verification；按风险定位相关领域指南 |
| 指南／技能维护 | 根规范、文档索引、目标文件，确定规则归属与任务分支 | 有重叠规则才追加相关指南；接口事实影响规则时再回查实现 |

以上是条件读取路径，不是每次通读清单。相关问题已有可靠依据后进入执行；出现新依赖或冲突再补读。已有上下文可复用，事实或实现变化后只复查受影响部分。

指南引用的是本仓库真实接口；新增示例必须标明是现有调用还是推荐实现模式。缺失的原语、注入入口、自动化或平台支持不得作为已存在前提。技能输入、完成条件及文档状态写法统一见 [文档索引](../README.md)，不在每份指南复制一套规则。
