# Flutter 页面、状态与异步交互

适用范围：页面、弹层和交互组件。组件选型见 [components.md](components.md)，播放边界见 [audio-lifecycle.md](audio-lifecycle.md)。

## 1. 状态归属

| 状态 | 默认所有者 | 处理方式 |
|---|---|---|
| 当前画面、按压、动画、局部 loading | StatefulWidget/State | setState，限定本次操作范围 |
| 初始课程、词序、策略版本 | LessonPlan | 不在 build 中重建或洗牌 |
| 题目队列、重试次数 | LessonQuizController | 显式队列变更 |
| 选词、长期掌握与复习间隔 | LearningEngine/Policy | 页面消费决策，不复制算法 |
| SQLite 进度和设置 | DAO + 对应服务 | 与临时 UI 状态分开 |

单个布尔 loading 不应同时表示“正在查库”“页面已切换”和“播放中”。只有业务确实互斥才共用锁；不要为此默认引入状态框架。

## 2. 读与写的差异

- 稳定的一次性 Future 在 initState 或明确刷新事件中创建，不能在 build 中触发重复查询。
- 查询覆盖 loading、空数据、成功和失败；失败应有可重新操作的出口，不能只有一段不可点击的“重试”文字。
- 关键写入等待真实成功后推进课程、关闭弹层或更新已保存状态；若使用乐观 UI，失败必须回滚或清楚恢复。
- 辅助曝光/播放统计不阻塞儿童操作，但仍需处理错误。不能把其降级规则套用到作答和设置。

以下为**推荐实现模式**，用于改动涉及的事件处理，不表示当前所有页面已实现：

```dart
Future<void> runAction(Future<void> Function() action) async {
  if (_loading) return;
  setState(() => _loading = true);
  try {
    await action();
    if (!mounted) return;
    // 在此处理经确认的成功结果。
  } catch (error, stackTrace) {
    if (!mounted) return;
    // 记录技术原因，并设置适合本页面的温和重试状态。
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

示例中的 `_loading` 与失败 UI 由目标页面定义；不能原样复制后省略错误反馈。存在多个请求时还要核对操作身份，`mounted` 不能证明结果属于当前题。

## 3. 时间、取消与迟到结果

- 每次展示有独立身份；切词/阶段变化使旧 token 失效，再取消对应 Timer。
- `await` 后核对 mounted、当前课程/题目身份；旧播放器、旧保存和旧动画的回调不能解锁下一题。
- dispose 负责释放自己的 Timer、动画、订阅与播放器；外部注入实例由其所有者释放。
- 首帧回调也可能晚于页面离开，使用状态前核对存活；不把首帧回调成功登记当成初始化已经完成。
- 当前尚无统一前后台恢复实现，见 [实施状态](../product_status.md)；涉及相关代码时先写清恢复规则，不能声称保留 State 就完成会话恢复。

## 4. 导航和接口

现有学习页构造为 `WordLearningPage(plan: plan, lessonSize: count, audio: ..., attemptRecorder: ...)`。`category/initialIndex` 已不是它的当前接口。

- 开课先生成计划，再 `Navigator.push`；完成课到庆祝页用替换路由，避免返回已完成课继续写入。
- Home/More 的目标由课程流程决定，回调不能暗中重置分类或重复推进默认轮换。
- 连续点击只启动一次操作，失败后解除锁；界面离开后不执行迟到导航。
- `audio` 和 `attemptRecorder` 是当前已有的最小注入点，曝光/播放统计仍绑定进度单例。需要验证持久化时不能只替换 attemptRecorder 就称全链路隔离。

## 5. 布局与产品表达

- 儿童页面以图片和声音传意，保留稳定主操作与即时视觉反馈；家长设置中文，儿童学习不默认显示翻译。
- 根据可用约束调整内容尺寸，避免写死设备型号；测试小高度、长单词、二选一和四选一。
- 保留 SafeArea、语义标签与合适的点击区域，复用 [设计系统](../design_system.md)。文字缩放与方向为全局策略，不在局部页面另设一套。
- UI 文案表达用户可采取的动作，不出现 SQL、迁移、token 或内部评审状态。

## 6. 验收范围

本次涉及的加载、失败、再次点击、快速连点、延迟返回和路由离开都要检查。播放器替身能证明页面等待顺序，不能证明真机音频输出；页面测试中数据库错误被吞掉，也不证明统计成功。
