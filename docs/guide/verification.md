# 验证入口与证据边界

验证策略见 [test-case-generator](../../.agents/skills/test-case-generator/SKILL.md)。先选择能观察本次错误后果的最小边界，不以用例数或全绿替代业务正确性。

## 1. 可直接执行的入口

默认从仓库根目录执行；缺依赖按所属锁文件安装，先确认 SDK 满足 `pubspec.lock`。

| 检查 | 命令 | 能证明 |
|---|---|---|
| 文档引用与记忆结构 | `python3 tool/check_docs.py` | 本地引用、必要入口、预算与记忆标记符合检查项 |
| 差异空白 | `git diff --check` | 已跟踪差异无空白错误；不替代未跟踪文件检查 |
| Dart 格式 | `dart format --output=none --set-exit-if-changed lib test` | 当前格式与 formatter 一致 |
| 静态分析 | `flutter analyze --no-pub` | 当前 analyzer/lint 结果 |
| 定向测试 | `flutter test --no-pub test/learning_engine_test.dart` | 所选用例实际断言的契约 |
| Flutter 测试集 | `flutter test --no-pub` | 当前测试集，不包括真实 iOS 插件与 Archive |
| 配图工具 | `node --test scripts/dreamina-word-generator/test/*.test.mjs` | 现有本地处理与参数用例 |
| iOS | 见 [发布指南](../ios_release.md) | 按实际构建/设备证据划定范围 |

当前没有统一 Flutter/Node 验证脚本、CI 和固定 SDK 配置；不能把本页表格描述为自动流水线已经上线。

## 2. 现有检查的保护范围

| 文件 | 主要保护 | 限制 |
|---|---|---|
| learning_engine_test | 决策、状态、间隔和 seed 行为 | 不证明页面保存链路 |
| lesson_session_service_test | 进度输入到计划/选项映射 | 多数从内存事实构造 |
| lesson_quiz_controller_test | 尾部补间隔与重试队列 | 不证明 UI 持久化 |
| database_migration_test | 生产 AppDatabase/DAO 在 SQLite FFI 的行为 | 测试目录隔离与全量结构等价仍需核对 |
| word_learning_page_test | 首播/重播、选项、纠错、鼓励与完成时序 | 多个 legacy 计划及辅助单例错误被吞，不等于生产链路通过 |
| resource_validation_test | 配置引用存在、唯一性及本期内容快照 | 不验证图意、完整音频解码或发音 |
| audio_playback_service_test | 权重配置 | 当前不保护真实播放器竞争/超时 |
| app_ui_policy/category_card_test | 缩放/设置文案与卡片契约 | 不替代完整视觉验收 |

## 3. 环境失败的处理

本次初次全量 Flutter 测试在连接 flutter_tester 阶段报 `Invalid WebSocket upgrade request`，移除该子进程代理并为回环地址设置 bypass 后通过。若同样连接阶段失败，可在不改全局代理的前提下执行：

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
  -u http_proxy -u https_proxy -u all_proxy \
  NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 \
  flutter test --no-pub
```

这是已观察问题的定向处理，不要求每次测试清空代理；与依赖下载、外部生成调用的联网需要分开。进程未连接、编译失败、用例断言失败分别记录，不一概定性为业务失败。

## 4. 失败与交付

- 失败先判断实现缺陷、测试缺陷、预期变化或环境问题；不能改断言来迁就当前输出。
- 已有检查有足够保护时复用；新缺陷需要永久回归时，优先扩展相关文件并确认目标错误会让它失败。
- 分析器 warning/info 造成退出失败如实报告，不为了 CI 绿把 `--no-fatal-infos` 当默认修复。
- 交付列实际命令/范围、结果、未验证项和关键限制。源码规范与测试数量不是运行证据。

## 5. 文档工具的维护边界

`tool/check_docs.py` 是标准库脚本，无外部依赖和写操作。新增文档或记忆仍需人工判断事实来源；新增检查必须针对明确的文档失效模式，不能用“文档越多越好”增加模板要求。
