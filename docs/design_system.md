# HopEnglish 设计语言规范

> 专为 2-5 岁幼儿打造的温暖明亮设计系统

---

## 一、设计理念

### 1.1 核心原则

| 原则 | 说明 | 实现方式 |
|------|------|----------|
| **温暖** | 营造安全、快乐的学习氛围 | 橙黄暖色系为主，避免冷硬色调 |
| **明亮** | 吸引幼儿注意力，激发探索欲 | 高饱和度色彩 + 奶油白背景 |
| **护眼** | 保护幼儿视力健康 | 避免纯白/纯黑强对比，柔和渐变 |
| **友好** | 传递亲切感，无压力体验 | 大圆角、柔和阴影、无惩罚色 |
| **清晰** | 便于幼儿识别交互元素 | 层次分明，主次明确 |

### 1.2 设计关键词

```
温暖 · 明亮 · 圆润 · 快乐 · 安全 · 柔和 · 活力
```

### 1.3 目标用户特征

- **年龄**：2-5 岁幼儿
- **视觉偏好**：高饱和度、明亮色彩
- **认知特点**：形象思维，依赖视觉反馈
- **交互习惯**：喜欢点按和重复
- **使用场景**：白天为主，横屏使用

---

## 二、色彩系统

### 2.1 主色调

| 名称 | 色值 | 预览 | 用途 |
|------|------|------|------|
| **蜜橘橙** | `#FF8A50` | 🟠 | 主要按钮、品牌色、核心交互 |
| 蜜橘橙-浅 | `#FFBB80` | 🟠 | 悬停状态、渐变起点 |
| 蜜橘橙-深 | `#E86A30` | 🟠 | 按下状态、阴影色 |

### 2.2 辅助色

| 名称 | 色值 | 预览 | 用途 |
|------|------|------|------|
| **薄荷青** | `#4ECDC4` | 🔵 | 次要按钮、信息提示 |
| 薄荷青-浅 | `#7EEEE6` | 🔵 | 悬停状态 |

### 2.3 强调色

| 名称 | 色值 | 预览 | 用途 |
|------|------|------|------|
| **柠檬黄** | `#FFE066` | 🟡 | 星星、成就、粒子特效 |
| 柠檬黄-浅 | `#FFF0A0` | 🟡 | 高亮背景 |

### 2.4 功能色

| 名称 | 色值 | 预览 | 用途 |
|------|------|------|------|
| **魔法紫** | `#B388FF` | 🟣 | 魔术棒、属性叠加 |
| 魔法紫-浅 | `#D4BBFF` | 🟣 | 魔法渐变 |
| **成长绿** | `#7ED957` | 🟢 | 完成标记、鼓励反馈 |
| **珊瑚红** | `#FF6B6B` | 🔴 | 护眼休息提示（温和） |

### 2.5 背景色

| 名称 | 色值 | 预览 | 用途 |
|------|------|------|------|
| **奶油白** | `#FFF9F0` | ⬜ | 主页面背景 |
| **暖杏色** | `#FFECD2` | 🟨 | 卡片背景、分区 |
| **纯白** | `#FFFFFF` | ⬜ | 卡片表面、弹窗 |

### 2.6 文字色

| 名称 | 色值 | 用途 |
|------|------|------|
| **深灰** | `#4A4A4A` | 主要文字（避免纯黑） |
| **中灰** | `#7A7A7A` | 次要文字 |
| **浅灰** | `#B0B0B0` | 提示文字 |
| **纯白** | `#FFFFFF` | 按钮/深色背景上的文字 |

### 2.7 分类主题色

每个学习主题有专属代表色，帮助孩子形成视觉记忆。

> **注意**：分类颜色属于业务配置，定义在 `CategoryConfig` 中（而非 `AppTheme`），便于动态新增分类。

| 主题 | 色值 | 预览 | 配置位置 |
|------|------|------|----------|
| 🦁 动物世界 | `#FFB347` | 🟠 | `CategoryConfig.categories` |
| 🍎 美味食物 | `#FF5C7A` | 🔴 | `CategoryConfig.categories` |
| 🚗 交通工具 | `#2EC4B6` | 🔵 | `CategoryConfig.categories` |
| 🏃 动作状态 | `#FFD166` | 🟡 | `CategoryConfig.categories` |
| 🏠 居家生活 | `#C3A6FF` | 🟣 | `CategoryConfig.categories` |
| 🎵 乐器声音 | `#FF85A2` | 🩷 | `CategoryConfig.categories` |
| 🌤️ 天气自然 | `#4CBF8A` | 🟢 | `CategoryConfig.categories` |

### 2.8 颜色语义使用规范（重要）

为符合产品需求中的“可预测性原则”（同样的动作永远产生同样的结果）与“无失败态原则”（不出现惩罚/错误暗示），颜色必须做到**同色同义**、**一义一色**：

#### A. 功能色（语义色）——表示“状态/反馈”，不表示“主题”

- **主交互/确认（Primary）**：`#FF8A50`（蜜橘橙）  
  用于主要按钮、核心交互（如 Next）。
- **信息/次要（Secondary）**：`#4ECDC4`（薄荷青）  
  用于次要按钮、提示信息等“中性状态”，避免用于奖励与警示。
- **奖励/成就（Accent）**：`#FFE066`（柠檬黄）  
  只用于星星、成就、粒子特效等“奖励反馈”。
- **变化/叠加（Magic）**：`#B388FF`（魔法紫）  
  只用于魔术棒与“属性叠加”相关的交互与动效。
- **完成/鼓励（Success）**：`#7ED957`（成长绿）  
  只用于完成标记、鼓励反馈，不用于主题识别。
- **休息提醒（Warm Alert）**：`#FF6B6B`（珊瑚红）  
  只用于护眼休息提示；避免用作“错误/失败”的表达。

#### B. 分类主题色——表示“主题识别”，不承担“状态/反馈”语义

- **推荐用法**（更舒适、统一、耐看）：
  - 卡片边框、角标、标签色块
  - 点击水波纹/高亮背景（低透明度）
  - 主题入口插画的点缀色
- **避免用法**（容易不舒适或语义混乱）：
  - 用分类色作为正文/标题文字颜色（尤其黄/浅色在白底上对比不足）
  - 用分类色表示成功/警示/奖励等状态（会与功能色冲突）

#### C. 简单落地规则（开发检查清单）

- “点了有奖励/成就感”的反馈 → 用 **Accent（柠檬黄）**
- “发生了魔法变化/叠加状态” → 用 **Magic（魔法紫）**
- “完成/已学会/达成” → 用 **Success（成长绿）**
- “休息/护眼提醒” → 用 **Warm Alert（珊瑚红）**
- “这是什么主题？” → 用 **分类主题色**（但文字优先用深灰）

---

## 三、排版规范

### 3.1 字体选择

| 场景 | 字体 | 代码常量 | 说明 |
|------|------|----------|------|
| 单词/标题展示 | **Fredoka** | `AppTheme.fontFamilyDisplay` | 圆润童趣，适合幼儿 |
| 正文/说明 | **Nunito** | `AppTheme.fontFamilyBody` | 简洁易读 |

### 3.2 字体文件

字体文件存放在 `assets/fonts/` 目录：

```
assets/fonts/
├── Fredoka-Regular.ttf    (400)
├── Fredoka-Medium.ttf     (500)
├── Fredoka-SemiBold.ttf   (600)
├── Fredoka-Bold.ttf       (700)
├── Nunito-Regular.ttf     (400)
├── Nunito-Medium.ttf      (500)
├── Nunito-SemiBold.ttf    (600)
└── Nunito-Bold.ttf        (700)
```

**下载来源**：[Google Fonts](https://fonts.google.com/)
- Fredoka: https://fonts.google.com/specimen/Fredoka
- Nunito: https://fonts.google.com/specimen/Nunito

### 3.3 文字样式

| 样式名称 | 字体 | 字号 | 字重 | 用途 |
|----------|------|------|------|------|
| `displayLarge` | Fredoka | 64px | Bold (700) | 超大展示标题（核心内容） |
| `displayMedium` | Fredoka | 40px | SemiBold (600) | 大号展示标题（次要内容） |
| `headlineMedium` | Fredoka | 22px | SemiBold (600) | 页面标题、区块标题 |
| `titleMedium` | Fredoka | 16px | Medium (500) | 卡片标题、列表项标题 |
| `bodyMedium` | Nunito | 14px | Regular (400) | 正文、说明文字 |

### 3.4 文字层级示意

```
┌──────────────────────────────────────┐
│                                      │
│         Apple                        │  ← displayLarge (Fredoka 64px)
│                                      │
│      Big Apple                       │  ← displayMedium (Fredoka 40px)
│                                      │
│   🍎 Foods                           │  ← headlineMedium (Fredoka 22px)
│                                      │
│   Animals                            │  ← titleMedium (Fredoka 16px)
│   点击图片听发音                       │  ← bodyMedium (Nunito 14px)
│                                      │
└──────────────────────────────────────┘
```

---

## 四、间距与圆角

### 4.1 间距系统

采用 8px 基准的间距系统：

| 名称 | 数值 | 用途 |
|------|------|------|
| `spacingSmall` | 8px | 紧凑间距 |
| `spacingMedium` | 16px | 标准间距 |
| `spacingLarge` | 24px | 宽松间距 |
| `spacingXLarge` | 32px | 区块间距 |

### 4.2 圆角系统

大圆角传递友好、安全的视觉感受：

| 名称 | 数值 | 用途 |
|------|------|------|
| `radiusSmall` | 8px | 小型元素 |
| `radiusMedium` | 16px | 标签、小按钮 |
| `radiusLarge` | 24px | 卡片、弹窗 |
| `radiusXLarge` | 28px | 主要按钮 |
| `radiusCircle` | 999px | 圆形按钮/头像 |

---

## 五、组件样式

### 5.1 按钮

#### 主要按钮（Primary Button）

```
┌─────────────────────────────────┐
│                                 │
│         下一个 →                 │
│                                 │
└─────────────────────────────────┘

背景色: #FF8A50 (蜜橘橙)
文字色: #FFFFFF
圆角: 28px
内边距: 40px × 20px
阴影: 0 4px 8px rgba(232, 106, 48, 0.25)
```

#### 分类卡片

```
┌─────────────────────────────────┐
│                                 │
│        🦁                       │
│                                 │
│     动物世界                     │
│                                 │
└─────────────────────────────────┘

背景色: #FFFFFF
边框: 主题色渐变边框
圆角: 24px
阴影: 0 4px 12px rgba(176, 176, 176, 0.12)
```

#### 魔术棒按钮

```
    ┌───────┐
    │  ✨   │
    └───────┘
    
常态背景: #B388FF (魔法紫)
激活背景: 魔法渐变
圆角: 圆形
尺寸: 56px × 56px
```

### 5.2 卡片

| 属性 | 值 |
|------|-----|
| 背景色 | `#FFFFFF` |
| 圆角 | 24px |
| 阴影 | `0 4px 12px rgba(176, 176, 176, 0.12)` |
| 内边距 | 16px |

### 5.3 进度指示

| 属性 | 值 |
|------|-----|
| 轨道色 | `#FFECD2` (暖杏色) |
| 进度色 | `#FF8A50` (蜜橘橙) |
| 高度 | 8px |
| 圆角 | 4px |

---

## 六、渐变系统

### 6.1 背景渐变

```
backgroundGradient
┌─────────────────────┐
│  #FFF9F0 (奶油白)   │ ← 顶部
│          ↓          │
│  #FFECD2 (暖杏色)   │ ← 底部
└─────────────────────┘

方向: 从上到下
用途: 主页面背景
```

### 6.2 主色渐变

```
primaryGradient
┌─────────────────────┐
│  #FFBB80            │ ← 左上
│          ↘          │
│            #FF8A50  │ ← 右下
└─────────────────────┘

用途: 主要按钮、强调卡片
```

### 6.3 魔法渐变

```
magicGradient
┌─────────────────────────────┐
│ #D4BBFF → #B388FF → #FFE066 │
└─────────────────────────────┘

用途: 魔术棒激活状态、属性叠加动效
```

### 6.4 庆祝粒子色

用于完成主题后的撒花动画：

```
celebrationColors = [
  #FFE066  柠檬黄
  #FF8A50  蜜橘橙
  #B388FF  魔法紫
  #7ED957  成长绿
  #4ECDC4  薄荷青
  #FF85A2  樱花粉
]
```

---

## 七、阴影系统

### 7.1 卡片阴影

```css
box-shadow: 0 4px 12px rgba(176, 176, 176, 0.12);
```

柔和、轻微的浮起效果，不喧宾夺主。

### 7.2 按钮阴影

```css
box-shadow: 0 4px 8px rgba(232, 106, 48, 0.25);
```

使用主色调的阴影，增强品牌感和点击欲望。

---

## 八、动效规范

### 8.1 时长定义

| 名称 | 时长 | 用途 |
|------|------|------|
| `durationFast` | 150ms | 微交互（按钮反馈） |
| `durationNormal` | 300ms | 常规过渡 |
| `durationSlow` | 500ms | 强调动效（撒花、完成） |

### 8.2 核心动效

| 场景 | 动效 | 说明 |
|------|------|------|
| 点击图片 | Q 弹缩放 | `scale: 1 → 0.95 → 1.05 → 1` |
| 切换单词 | 淡入滑动 | 新内容从右侧淡入 |
| 魔术棒激活 | 旋转发光 | 360° 旋转 + 光晕扩散 |
| 完成主题 | 撒花粒子 | 多彩粒子从底部喷发 |
| 星星获得 | 弹跳闪烁 | 放大弹跳 + 金光闪烁 |

### 8.3 按钮冷却

为防止幼儿连续快速点击导致页面混乱：

- **冷却时间**：500ms
- **视觉反馈**：冷却期间按钮轻微变灰 + 抖动

---

## 九、无障碍与护眼

### 9.1 对比度

- 主要文字与背景对比度 ≥ 4.5:1
- 避免纯白 `#FFFFFF` 与纯黑 `#000000` 的直接对比

### 9.2 护眼设计

- 背景使用奶油白 `#FFF9F0` 而非纯白
- 文字使用深灰 `#4A4A4A` 而非纯黑
- 提供 15 分钟护眼休息提醒

### 9.3 点击区域

- 所有可交互元素最小点击区域：48px × 48px
- 主要按钮推荐尺寸：≥ 80px 高度

---

## 十、代码引用

### 10.1 导入

```dart
import 'package:hopenglish/core/theme/app_theme.dart';
```

### 10.2 应用主题

```dart
MaterialApp(
  theme: AppTheme.theme,
  // ...
)
```

### 10.3 使用示例

```dart
// 功能色（主题/状态/反馈）
Container(color: AppTheme.primary)
Container(color: AppTheme.accent)

// 分类颜色（业务配置，在 CategoryConfig 中）
import 'package:hopenglish/core/config/category_config.dart';
final category = CategoryConfig.categories.first;
Container(color: category.color)

// 字体（已内置在文字样式中）
// Fredoka: AppTheme.fontFamilyDisplay
// Nunito: AppTheme.fontFamilyBody

// 文字样式（自动应用对应字体）
Text('Apple', style: AppTheme.displayLarge)      // Fredoka Bold 64px
Text('Big Apple', style: AppTheme.displayMedium) // Fredoka SemiBold 40px
Text('Animals', style: AppTheme.headlineMedium)  // Fredoka SemiBold 22px
Text('Lion', style: AppTheme.titleMedium)        // Fredoka Medium 16px
Text('点击听发音', style: AppTheme.bodyMedium)    // Nunito Regular 14px

// 渐变
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.backgroundGradient,
  ),
)

// 阴影
Container(
  decoration: BoxDecoration(
    boxShadow: AppTheme.cardShadow,
  ),
)

// 间距
Padding(padding: EdgeInsets.all(AppTheme.spacingMedium))

// 圆角
BorderRadius.circular(AppTheme.radiusLarge)
```

---

## 附录：色彩情绪速查

```
🟠 蜜橘橙  →  快乐 · 活力 · 温暖 · 探索
🔵 薄荷青  →  平静 · 信任 · 安全 · 放松
🟡 柠檬黄  →  阳光 · 正向 · 成就 · 惊喜
🟣 魔法紫  →  神奇 · 变化 · 想象力 · 期待
🟢 成长绿  →  成长 · 鼓励 · 自然 · 健康
🩷 樱花粉  →  柔和 · 可爱 · 音乐 · 愉悦
🔴 珊瑚红  →  温和提醒 · 休息 · 关怀
```

---

*文档版本：1.0*  
*最后更新：2024年*  
*适用于：HopEnglish 幼儿英语启蒙 App*

