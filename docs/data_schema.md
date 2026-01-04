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
分类 (Category)
├── 基本信息：id, emoji, name, color
└── 单词列表 (words)
    └── 单词 (Word)
        ├── 基础态：id, name, image, audio
        └── 短语态：phrase（可选）
            └── name, attribute, image, audio
```

---

## 二、文件结构

### 2.1 文件位置

```
assets/
└── data/
    └── categories.json    # 分类与单词配置
```

### 2.2 根结构

采用**数组结构**作为根节点：

```json
[
  { "id": "animals", ... },
  { "id": "foods", ... },
  ...
]
```

**设计理由：**
- 文件名 `categories.json` 已表达语义
- 无需 `version` 等元数据（数据随 App 发布）
- 更简洁，少一层嵌套

---

## 三、数据模型

### 3.1 Category（分类）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✅ | 唯一标识，用于路由和存储 |
| `emoji` | string | ✅ | 分类图标（emoji 字符） |
| `name` | string | ✅ | 显示名称（英文） |
| `color` | string | ✅ | 主题色，十六进制格式 `#RRGGBB` |
| `words` | array | ✅ | 单词列表 |

**示例：**

```json
{
  "id": "animals",
  "emoji": "🦁",
  "name": "Animals",
  "color": "#FFB347",
  "words": [...]
}
```

### 3.2 Word（单词）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✅ | 唯一标识 |
| `name` | string | ✅ | 单词名称（英文） |
| `image` | string | ✅ | 图片相对路径 |
| `audio` | string | ✅ | 音频相对路径 |
| `phrase` | object | ❌ | 短语态，可选 |

**示例：**

```json
{
  "id": "lion",
  "name": "Lion",
  "image": "animals/lion.png",
  "audio": "animals/lion.mp3",
  "phrase": { ... }
}
```

### 3.3 Phrase（短语态）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | ✅ | 短语名称（英文） |
| `attribute` | string | ✅ | 属性标识（如 big, angry, running） |
| `image` | string | ✅ | 变化后的图片路径 |
| `audio` | string | ✅ | 短语音频路径 |

**示例：**

```json
{
  "name": "Angry Lion",
  "attribute": "angry",
  "image": "animals/lion_angry.png",
  "audio": "animals/angry_lion.mp3"
}
```

---

## 四、完整示例

```json
[
  {
    "id": "animals",
    "emoji": "🦁",
    "name": "Animals",
    "color": "#FFB347",
    "words": [
      {
        "id": "lion",
        "name": "Lion",
        "image": "animals/lion.png",
        "audio": "animals/lion.mp3",
        "phrase": {
          "name": "Angry Lion",
          "attribute": "angry",
          "image": "animals/lion_angry.png",
          "audio": "animals/angry_lion.mp3"
        }
      },
      {
        "id": "dog",
        "name": "Dog",
        "image": "animals/dog.png",
        "audio": "animals/dog.mp3",
        "phrase": {
          "name": "Running Dog",
          "attribute": "running",
          "image": "animals/dog_running.png",
          "audio": "animals/running_dog.mp3"
        }
      }
    ]
  },
  {
    "id": "foods",
    "emoji": "🍎",
    "name": "Foods",
    "color": "#FF5C7A",
    "words": [
      {
        "id": "apple",
        "name": "Apple",
        "image": "foods/apple.png",
        "audio": "foods/apple.mp3",
        "phrase": {
          "name": "Big Apple",
          "attribute": "big",
          "image": "foods/apple_big.png",
          "audio": "foods/big_apple.mp3"
        }
      }
    ]
  }
]
```

---

## 五、资源路径约定

### 5.1 目录结构

```
assets/
├── data/
│   └── categories.json           # 数据配置
├── images/
│   └── words/
│       ├── animals/
│       │   ├── lion.png          # 基础态
│       │   ├── lion_angry.png    # 短语态
│       │   ├── dog.png
│       │   └── dog_running.png
│       └── foods/
│           ├── apple.png
│           └── apple_big.png
└── audio/
    └── words/
        ├── animals/
        │   ├── lion.mp3
        │   ├── angry_lion.mp3
        │   ├── dog.mp3
        │   └── running_dog.mp3
        └── foods/
            ├── apple.mp3
            └── big_apple.mp3
```

### 5.2 路径规则

| 资源类型 | JSON 中的值 | 完整路径 |
|----------|-------------|----------|
| 图片 | `animals/lion.png` | `assets/images/words/animals/lion.png` |
| 音频 | `animals/lion.mp3` | `assets/audio/words/animals/lion.mp3` |

**代码中拼接：**

```dart
// 图片
'assets/images/words/${word.image}'

// 音频
'assets/audio/words/${word.audio}'
```

### 5.3 命名规范

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 基础态图片 | `{word}.png` | `lion.png` |
| 短语态图片 | `{word}_{attribute}.png` | `lion_angry.png` |
| 基础态音频 | `{word}.mp3` | `lion.mp3` |
| 短语态音频 | `{attribute}_{word}.mp3` | `angry_lion.mp3` |

---

## 六、扩展说明

### 6.1 结构 vs 内容

| 概念 | 含义 | 修改方式 |
|------|------|----------|
| **结构** | 字段名、类型、嵌套关系 | 需改代码 |
| **内容** | 具体的分类、单词数据 | 只改 JSON |

### 6.2 内容扩展（无需改代码）

**添加新分类：**

```json
[
  { "id": "animals", ... },
  { "id": "foods", ... },
  { "id": "colors", "emoji": "🎨", "name": "Colors", "color": "#FF6B6B", "words": [...] }
]
```

**添加新单词：**

```json
{
  "id": "animals",
  "words": [
    { "id": "lion", ... },
    { "id": "dog", ... },
    { "id": "elephant", "name": "Elephant", ... }
  ]
}
```

### 6.3 无短语态的单词

部分单词可能没有短语态，`phrase` 字段可省略：

```json
{
  "id": "water",
  "name": "Water",
  "image": "foods/water.png",
  "audio": "foods/water.mp3"
}
```

代码中需处理 `phrase == null` 的情况。

---

## 七、Dart 模型对照

### 7.1 模型类

```dart
// lib/models/category.dart
class Category {
  final String id;
  final String emoji;
  final String name;
  final Color color;
  final List<Word> words;
}

// lib/models/word.dart
class Word {
  final String id;
  final String name;
  final String image;
  final String audio;
  final Phrase? phrase;
}

// lib/models/phrase.dart
class Phrase {
  final String name;
  final String attribute;
  final String image;
  final String audio;
}
```

### 7.2 使用示例

```dart
// 加载数据
final categories = await CategoryService.loadCategories();

// 获取分类
final animals = categories.firstWhere((c) => c.id == 'animals');

// 获取单词
final lion = animals.words.firstWhere((w) => w.id == 'lion');

// 获取图片路径
final imagePath = 'assets/images/words/${lion.image}';

// 判断是否有短语态
if (lion.phrase != null) {
  final phraseName = lion.phrase!.name; // "Angry Lion"
}
```

---

## 八、MVP 内容规划

### 8.1 分类列表

| id | emoji | name | 单词数 |
|----|-------|------|--------|
| animals | 🦁 | Animals | 5 |
| foods | 🍎 | Foods | 5 |
| vehicles | 🚗 | Vehicles | 5 |
| actions | 🏃 | Actions | 5 |
| home | 🏠 | My Home | 5 |
| music | 🎵 | Music | 5 |
| nature | 🌤️ | Nature | 5 |

### 8.2 单词列表（示例）

**Animals:**
- Lion → Angry Lion
- Dog → Running Dog
- Cat → Sleeping Cat
- Bird → Flying Bird
- Fish → Swimming Fish

**Foods:**
- Apple → Big Apple
- Banana → Yellow Banana
- Milk → Hot Milk
- Cookie → Yummy Cookie
- Water → Cold Water

---

## 九、检查清单

添加新内容时，确保：

- [ ] JSON 格式正确（可用在线 JSON 校验工具）
- [ ] id 全局唯一
- [ ] color 使用 `#RRGGBB` 格式
- [ ] 图片文件已放入对应目录
- [ ] 音频文件已放入对应目录
- [ ] 路径与 JSON 中的值匹配

---

*文档版本：1.0*  
*最后更新：2026-01-04*

