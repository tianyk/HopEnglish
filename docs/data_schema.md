# 数据配置设计方案

> 本文档定义了 HopEnglish 应用的内容数据结构规范

---

## 一、设计概述

### 1.1 设计目标

| 目标 | 说明 |
|------|------|
| **集中管理** | 所有分类和单词数据集中在一个 JSON 文件中 |
| **易于扩展** | 添加新分类/单词只需修改 JSON，无需改代码 |
| **非开发者友好** | 产品/运营可直接编辑内容 |
| **类型安全** | 通过 Dart 模型类保证类型正确 |
| **资源关联** | 图片、音频路径规范化，便于管理 |

### 1.2 设计原则

1. **KISS（保持简单）**：结构尽量扁平，避免过度嵌套
2. **YAGNI（不过度设计）**：只定义当前需要的字段
3. **约定优于配置**：资源路径遵循统一约定

### 1.3 数据层级

```
Category → words[] → Word
```

---

## 二、文件位置

```
assets/data/categories.json
```

根结构为**数组**，每个元素是一个 Category。

---

## 三、数据模型

### 3.1 Category（分类）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✅ | 唯一标识 |
| `emoji` | string | ⚠️ | 分类图标（emoji），与 image 二选一 |
| `image` | string | ⚠️ | 分类图标（图片路径），与 emoji 二选一 |
| `name` | string | ✅ | 显示名称（英文） |
| `color` | string | ✅ | 主题色 `#RRGGBB` |
| `words` | array | ✅ | 单词列表 |

> ⚠️ `emoji` 和 `image` 至少需要一个，优先使用 `image`。

### 3.2 Word（单词）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✅ | 单词/学习项标识（**在同一分类内唯一**；允许跨分类重复） |
| `name` | string | ✅ | 单词名称（英文） |
| `emoji` | string | ⚠️ | 单词图标（emoji），与 image 二选一 |
| `image` | string | ⚠️ | 单词图片路径，与 emoji 二选一 |
| `audio` | string | ✅ | 音频路径 |

> ⚠️ `emoji` 和 `image` 至少需要一个，优先使用 `image`。

**稳定标识建议（用于统计/存储/调度）：**

- `wordKey = $categoryId:$wordId`（例如：`foods:orange`、`colors:orange`）

---

## 四、JSON 示例

```json
[
  {
    "id": "animals",
    "emoji": "🦁",
    "name": "Animals",
    "color": "#FFB347",
    "words": [
      { "id": "lion", "name": "Lion", "emoji": "🦁", "audio": "animals/lion.mp3" },
      { "id": "dog", "name": "Dog", "emoji": "🐕", "audio": "animals/dog.mp3" }
    ]
  }
]
```

---

## 五、资源路径约定

### 5.1 目录结构

| 类型 | 路径 |
|------|------|
| 数据文件 | `assets/data/categories.json` |
| 分类图片 | `assets/images/categories/` |
| 单词图片 | `assets/images/words/{category}/` |
| 单词音频 | `assets/audio/words/{category}/` |

### 5.2 路径映射

| JSON 中的值 | 完整路径 |
|-------------|----------|
| `categories/animals.png` | `assets/images/categories/animals.png` |
| `animals/lion.png` | `assets/images/words/animals/lion.png` |
| `animals/lion.mp3` | `assets/audio/words/animals/lion.mp3` |

### 5.3 网络资源

以 `http://` 或 `https://` 开头的路径视为网络资源，直接使用。

---

## 六、Dart 模型

模型位置：`lib/src/models/`

| 模型 | 文件 | 说明 |
|------|------|------|
| `Category` | `category.dart` | 分类模型，包含 `fromJson`/`toJson` |
| `Word` | `word.dart` | 单词模型，包含 `fromJson`/`toJson` |

**关键 getter：**

| Getter | 说明 |
|--------|------|
| `hasImage` | 是否有图片 |
| `isImageNetwork` | 图片是否为网络资源 |
| `imagePath` | 完整图片路径（自动拼接） |
| `audioPath` | 完整音频路径（自动拼接） |

---

## 七、内容规划

### 7.1 分类列表

| id | emoji | name | 单词数 |
|----|-------|------|--------|
| animals | 🦁 | Animals | 34 |
| foods | 🍎 | Food & Drink | 38 |
| body | 🙂 | My Body | 12 |
| actions | 🏃 | Actions | 16 |
| vehicles | 🚗 | Vehicles | 17 |
| home | 🏠 | Home & Family | 24 |
| colors | 🎨 | Colors & Shapes | 15 |
| clothes | 👕 | Clothes | 11 |
| feelings | 😊 | Feelings | 8 |
| nature | 🌤️ | Nature & Weather | 16 |
| places | 🏫 | Places & People | 23 |
| music | 🎵 | Music & Play | 16 |

### 7.2 单词示例

- **Animals**: Lion, Dog, Cat, Bird, Fish
- **Foods**: Apple, Banana, Milk, Cookie, Water

---

## 八、检查清单

添加新内容时确保：

- [ ] JSON 格式正确
- [ ] Category.id 全局唯一
- [ ] Word.id 在分类内唯一（允许跨分类重复）
- [ ] color 使用 `#RRGGBB` 格式
- [ ] emoji 或 image 至少有一个
- [ ] 资源文件已放入对应目录
- [ ] 路径与 JSON 中的值匹配

---

*文档版本：1.3 | 最后更新：2026-07-30*
