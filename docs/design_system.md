# HopEnglish 设计系统

状态：现行 Token 与实现约定，2026-10-18 核对。代码基准为 `lib/src/theme/app_theme.dart`，页面用法与能力缺口见 [实施状态](product_status.md)。本文件不宣称现有页面都已完成可访问性和设备验收。

## 1. 设计目标与页面层级

面向 2–5 岁儿童，以温暖、明亮、圆润的图音交互建立稳定联想。颜色与动画服务于操作反馈，不用装饰或文字说明争夺学习主体。

| 场景 | 主视觉 | 次要信息 | 交互要求 |
|---|---|---|---|
| 首页 | 当前可达的分类入口 | Word Library、设置 | 主次清楚，不默认加入成绩和排行榜 |
| 图音学习 | 单词图片、英语名称 | Listen/Slow、当前课进度 | 点击即时反馈，重复可预测 |
| 听音选图 | 播放入口与选项 | 简短英语指引 | 不出现惩罚/红叉；选错温和纠正 |
| 庆祝 | 语音与粒子 | Home/More 两个出口 | 现行实现不自动倒计时返回 |
| 家长设置 | 中文选项与当前选择 | 节奏说明 | 与儿童英语图音画面分开 |

首页去分类是专项需求，不能在实现主题时自动替换现有首页。主色与视觉不迁移 hdims 的医疗后台风格，借鉴的是规则、Token 和验收的对应关系。

## 2. 颜色 Token

| AppTheme 名称 | 当前值 | 语义 |
|---|---|---|
| primary / primaryLight / primaryDark | `#FFB347` / `#FFBB80` / `#E86A30` | 主交互与同系过渡/阴影 |
| secondary / secondaryLight | `#4ECDC4` / `#7EEEE6` | 次操作和中性信息 |
| accent / accentLight | `#FFE066` / `#FFF0A0` | 星星、成就和正向强调 |
| success | `#7ED957` | 正确/完成反馈 |
| warmAlert | `#FF6B6B` | 温和提醒；不能自动用于惩罚性错误 |
| background / backgroundWarm | `#FFF9F0` / `#FFECD2` | 页面与弱层次背景 |
| surface | `#FFFFFF` | 图片/选项/浮层表面 |
| cardBorder | `#F0DFC7` | 当前首页分类卡片统一边框 |
| textPrimary / textSecondary / textHint | `#4A4A4A` / `#7A7A7A` / `#B0B0B0` | 正文、次要信息、提示 |
| textOnColor | `#FFFFFF` | 有色表面文字，需检查实际对比度 |
| magic / magicLight | `#B388FF` / `#D4BBFF` | 保留 Token，不表示魔术棒功能已实现 |

分类 color 存于 `assets/data/categories.json`，由 Category 解析；不存在 CategoryConfig。主题色用于主题识别、低透明度选中/水波纹等，不取代成功/提醒的统一语义。

Token 值变化必须同步本表和代码，并核对所有真实调用方。局部内容图案色不必强行变成全局 Token；禁止每个页面另起一套品牌/状态体系。

## 3. 字体与文字样式

| 样式 | 字体/尺寸/字重 | 当前默认色 | 用途 |
|---|---|---|---|
| displayLarge | Fredoka / 64 / 700 | textPrimary | 单词与主展示 |
| displayMedium | Fredoka / 40 / 600 | textPrimary | 次级强调 |
| headlineMedium | Fredoka / 22 / 600 | primary | 页面/区块标题 |
| titleMedium | Fredoka / 16 / 500 | primary | 卡片、操作标签 |
| bodyMedium | Nunito / 14 / 默认常规 | textSecondary | 辅助说明 |

字体源在 `assets/fonts/`，由 pubspec 声明。优先使用现有 TextStyle，确需调整用 copyWith，不为相同层级反复定义新样式。

AppTextScaleBoundary 当前使用 `MediaQuery.withNoTextScaling`。这是现行全局策略，不代表已完成可访问性评估；不能在普通页面修改中擅自取消。中文家长界面的实际字形回退和最小设备表现需要另外核对。

## 4. 尺寸、圆角、阴影和渐变

| 类别 | Token/数值 | 用法 |
|---|---|---|
| 间距 | small 8、medium 16、large 24、xlarge 32 | 统一基本节奏；页面局部几何可按明确布局计算 |
| 圆角 | small 8、medium 16、large 24、xlarge 28 | 元素、按钮、卡片、浮层分层使用 |
| cardShadow | textHint alpha 0.12，blur 12，offset 0/4 | 有交互层次的卡片 |
| buttonShadow | primaryDark alpha 0.25，blur 8，offset 0/4 | 主操作 |
| backgroundGradient | background → backgroundWarm，自上而下 | 当前页面背景 |
| primaryGradient | primaryLight → primary，左上到右下 | 需要渐变的主色表达 |
| magicGradient | magicLight → magic → accent | 保留配置，不能据此开放未实现交互 |

`radiusCircle` 不是当前 AppTheme 常量；圆形使用 CircleBorder/BoxShape.circle 或具体组件约定。不把所有容器默认卡片化：图片选项可以有边框和阴影，辅助提示和普通文本不需要套卡片。

ThemeData 的 Material 按钮/卡片样式与页面自绘按钮不是同一个实现。修改主题后需要检查实际页面使用方式，不能只改 ThemeData 就宣称所有按钮同步。

## 5. 组件与页面约定

- 现有显示组件和限制见 [组件指南](guide/components.md)，不在此虚构统一按钮或组件预览页已经存在。
- CategoryCard 当前统一 cardBorder，分类色主要用于水波纹/高亮；不要恢复旧文档的各色粗边框。
- 当前学习页用 LayoutBuilder 收缩图像和间距；二选一/四选一布局由实际约束计算，不写死某个 iPhone 型号。
- 进度条目前页面计算并保证不回退，颜色仍使用分类色；它表示课程推进，不是掌握率。
- 儿童可交互元素的新建/改动目标为至少 48×48 逻辑像素；主要操作尽量更大。现有部分返回按钮为 44×44，是需在相关 UI 任务中核对的差异，不写成已全部符合。
- 使用 Semantics 表达按钮含义与选择/禁用状态；仅视觉变灰不足以说明不可操作。

## 6. 动效与播放

基础时长：durationFast 150ms、durationNormal 300ms、durationSlow 500ms；buttonCooldown 500ms。特定动作有自己的真实时长，例如学习反弹 300ms、错误晃动 420ms、最后答对停留 400ms，不能把基础时长表当成所有动画已统一。

立即视觉反馈可以先于声音；等待播放的锁定、重播不重新锁 Next、鼓励与下题衔接按 [音频指南](guide/audio-lifecycle.md) 执行。冷却、错误和加载是不同状态，不机械地全部“变灰+抖动”。

## 7. 视觉验收

目前没有组件画廊或自动截图基准。修改视觉时至少比较本次受影响的真实画面，记录设备/窗口尺寸和内容状态：

1. 首页分类卡片与长名称、学习词与长单词、二选一和四选一。
2. 小高度、SafeArea、播放中/加载中/重试状态，确保主体与点击区域不被挤出。
3. 家长设置中文字形、选择态，完成页粒子和 Home/More 操作。
4. 正文和操作的实际对比度；暖色方案不自动等于达到 4.5:1。

15 分钟休息、魔术棒和家长锁均不能以设计 Token/文字常量存在宣称已上线，具体状态见实施状态文档。

## 8. 应用图标

品牌图标保留友好狮子、暖色、无文字和边框的方向；iOS 源图为 1024×1024、无 alpha、无自带圆角裁剪，具体操作见 [图标指南](app_icon_setup.md)。图标源、启动页与课程插图是不同用途，不把生成原图直接当商店合格产物。
