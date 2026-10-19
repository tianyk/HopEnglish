# 组件选用、复用与抽取

适用范围：`lib/src/pages/` 与 `lib/src/widgets/`。以实际调用和稳定输入决定复用，不以代码长度决定公共化。

## 1. 选型顺序

1. 搜索现有 widgets 和目标页面附近的私有组件。
2. 判断能否直接复用，或用已有组件组合。
3. 需要扩展时核对第二个真实使用场景，避免添加只为一个页面成立的布尔开关。
4. 无现有能力再新增，并明确它属于展示原语、领域组件或页面私有组件。

## 2. 当前组件清单

| 组件 | 输入与行为 | 适用边界 |
|---|---|---|
| `AdaptiveImage` | imagePath、尺寸、fit、placeholder、errorWidget | 本地/网络图片及 SVG 的显示适配 |
| `WordIcon` | Word、size、emojiSizeRatio、fit、errorWidget | 有 image 时显示图片，无 image 才显示 emoji |
| `CategoryCard` | Category、可空 onTap | 分类入口；统一边框、主题水波纹、Semantics |
| `LessonSettingsSheet` | selectedCount、onChanged | 领域设置组件，当前内部持久化，非纯展示原语 |
| `WordDirectorySheet` | Category、words、currentIndex、onWordSelected | 历史目录组件，当前未找到生产调用入口 |

源码位置均在 `lib/src/widgets/`。下列限制必须如实保留在选型判断中：

- `AdaptiveImage.errorWidget` 目前用于普通图片的 errorBuilder；SVG 分支没有同等错误占位实现。
- `WordIcon` 的 emoji 回退依据“没有配置图片”，不保证图片损坏后自动回退 emoji。
- `LessonSettingsSheet` 的回调当前先于保存成功，失败恢复未完成；不能把它当成事务成功通知。
- 返回按钮、Listen/Slow 按钮和页面头部仍有页面私有的重复实现，尚不存在通用 `AppButton` 或 `LearningHeader`。

## 3. 分层与目录

| 层级 | 可包含 | 不应包含 |
|---|---|---|
| 展示原语 | 图片适配、按钮壳、尺寸和语义 | DAO、课程选择、默认调用全局服务 |
| 领域复用 | Word/Category 表达、明确的课程设置 | 伪装成通用的多业务模式开关 |
| 页面私有 | 仅一页成立的阶段布局、动画组合 | 为“以后可能用”提前进入 widgets 根目录 |

当前没有专门的原语目录；出现真实复用再按功能建子目录，不为文档表格创建空目录。

## 4. 抽取门槛

- 同一交互已有两个实际调用方，或规范明确指定其为默认壳层，且输入输出稳定时再抽取。
- 抽取后立即让真实调用方复用；只移动一大块页面代码却继续依赖页面私有状态，不算公共组件。
- 通过 Widget、builder 和回调组合，避免 `isLearning/isLibrary/isCelebration` 连续扩张。
- 公共原语不隐式读写学习进度；领域组件若内置写入，API 明确说明保存语义、失败与回调时机。
- 不包装一个已有 Widget 而不增加稳定语义，也不把每段相似布局强行合成一个万能组件。

## 5. 示例与审查

现有的正确调用方式：

```dart
WordIcon(word: word, size: 180)
CategoryCard(category: category, onTap: () => startLesson(category))
```

示例中的 `word/category/startLesson` 是调用方数据与处理函数，不是新增的全局 API。

审查重点是：有没有绕过现有显示适配、有没有公共组件偷偷操作数据库、回调到底表示点击还是保存成功、禁用状态与 Semantics 是否一致。改造共用按钮时验证等待播放、手动重播、触控尺寸和样式同时保持，不只比较静态截图。
