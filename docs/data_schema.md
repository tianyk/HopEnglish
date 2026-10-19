# 内容数据 Schema 与资源路径

状态：现行内容契约，2026-10-18 按词表与模型核对。内容源为 `assets/data/categories.json`，顶层是 Category 数组。生成和采用流程见 [内容资源指南](guide/content-assets.md)。

## 1. Category

| 字段 | 类型 | 约束 |
|---|---|---|
| id | string | 全局唯一，稳定身份 |
| name | string | 英文名称 |
| color | string | `#RRGGBB`，Category.fromJson 转为 Color |
| emoji | string? | 与 image 至少一个非空；可同时存在 |
| image | string? | 分类图片相对文件名；优先显示 |
| words | Word[] | 分类学习项；当前内容保证足够构造选项 |

## 2. Word

| 字段 | 类型 | 约束 |
|---|---|---|
| id | string | 分类内唯一，跨分类允许重复 |
| name | string | 英文显示与发音文本 |
| nameZh | string? | 中文含义，辅助管理和生成语义，不自动显示在儿童画面 |
| emoji | string? | 与 image 至少一个非空；可同时存在 |
| image | string? | 单词图片相对文件名；优先显示 |
| audio | string | 当前本地正常音频相对文件名，后缀 `_normal.wav` |

运行时模型的 assert 不是 Release 内容校验器。新增内容需检查类型、空字符串、身份与资源引用，不能只依赖 fromJson 转型或工具任务成功。

## 3. 稳定身份与共享

- 学习项主键为 `categoryId:wordId`，例如 foods:orange 和 colors:orange 分开统计。
- 英文拼写不是主键；同分类多义词需独立 ID，改变 ID/分类需处理历史进度。
- 相同发音可共享音频，例如 Orange/Star 的跨分类条目；图意依分类分别表达。
- 图片工具使用 `categoryId/wordId` 任务键；TTS 当前只提取 id/name，筛选与输出限制见内容资源指南。

## 4. 实际路径映射

| 资源 | JSON 中的值示例 | 模型/播放器使用的位置 |
|---|---|---|
| 分类图 | `animals.png` | `assets/images/categories/animals.png` |
| 单词图 | `animals_dog.png` | `assets/images/words/animals_dog.png` |
| 正常音频 | `dog_normal.wav` | `assets/audio/words/dog_normal.wav` |
| 慢速音频 | 不新增 Word 字段 | 将 `_normal.wav` 替换为 `_slow.wav` |
| 完成/鼓励 | 非词条字段 | `assets/audio/celebrations/` 中四个 WAV |

词表不保存重复的 `assets/...` 前缀，也不按历史示例新建分类子目录。图片最终使用 `{category}_{word}.png`；分类图 `{category}.png`；当前图片生成器输出 512×512 透明 PNG。

模型 getter 可以识别 http(s) URL，但当前慢速远程音频分支和完整远程内容验收未完成。这里的 URL 类型支持不构成开放网络内容的产品承诺。

## 5. 当前配置示例

下例是现行字段与文件名的子集示例，不是完整分类内容；不能据此将正式词表覆盖成一个词。

```json
[
  {
    "id": "animals",
    "name": "Animals",
    "color": "#FFB347",
    "emoji": "🦁",
    "image": "animals.png",
    "words": [
      {
        "id": "dog",
        "name": "Dog",
        "nameZh": "狗",
        "emoji": "🐶",
        "image": "animals_dog.png",
        "audio": "dog_normal.wav"
      }
    ]
  }
]
```

Category/Word 实现位于 `lib/src/models/`，本地 imagePath/audioPath getter 负责拼接资源根目录；AudioPlaybackService 再移除 AssetSource 不需要的 `assets/` 前缀。

## 6. 内容快照

当前 12 分类、230 学习项。该快照用于盘点与本期资源测试，新增内容时允许按已确认需求更新，不能当作永久禁止扩展的算法约束。

| id | name | 学习项数 |
|---|---|---:|
| animals | Animals | 34 |
| foods | Food & Drink | 38 |
| body | My Body | 12 |
| actions | Actions | 16 |
| vehicles | Vehicles | 17 |
| home | Home & Family | 24 |
| colors | Colors & Shapes | 15 |
| clothes | Clothes | 11 |
| feelings | Feelings | 8 |
| nature | Nature & Weather | 16 |
| places | Places & People | 23 |
| music | Music & Play | 16 |

## 7. 内容验收

检查 JSON 类型、Category 唯一、Word 分类内唯一、颜色格式、图片/emoji、Normal/Slow 成对及 `pubspec.yaml` 声明。复用 `test/resource_validation_test.dart`，同时明确本次是否完成了图片语义与语音试听；测试通过不等于语义正确。
