# HopEnglish TTS Generator

批量生成单词音频（Normal / Slow）使用 Gemini TTS API。

## 安装

```bash
cd scripts/tts-generator
npm install
```

## 使用

### 基本用法

```bash
# 使用环境变量提供 API Key
GEMINI_API_KEY="your-key" node index.js

# 或通过参数提供
node index.js --api-key "your-key"
```

### 选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--api-key <key>` | Gemini API Key（必填，或通过环境变量 `GEMINI_API_KEY`） | - |
| `--input <path>` | 输入 JSON 文件路径 | `../../assets/data/categories.json` |
| `--output <path>` | 输出目录路径 | `../../assets/audio/words/v4` |
| `--model <id>` | 模型 ID | `gemini-2.5-flash-preview-tts` |
| `--voice <name>` | 语音名称 | `Sulafat` |
| `--accent <desc>` | 口音描述 | `General American English` |
| `--temperature <n>` | 温度 | `0.3` |
| `--dry-run` | 只打印计划，不请求 API | `false` |
| `-h, --help` | 显示帮助 | - |
| `-V, --version` | 显示版本 | - |

### 示例

```bash
# 使用默认配置
GEMINI_API_KEY="your-key" node index.js

# 使用英式口音
GEMINI_API_KEY="your-key" node index.js --accent "British English - Received Pronunciation (RP)"

# 使用不同的语音
GEMINI_API_KEY="your-key" node index.js --voice "Kore"

# Dry run（测试）
GEMINI_API_KEY="your-key" node index.js --dry-run

# 自定义输入输出路径
node index.js --api-key "your-key" \
  --input "/path/to/input.json" \
  --output "/path/to/output"
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `GEMINI_API_KEY` | Gemini API Key（必填） |
| `HTTPS_PROXY` | HTTPS 代理（可选，例如：`http://127.0.0.1:7890`） |
| `HTTP_PROXY` | HTTP 代理（可选，`HTTPS_PROXY` 优先） |

## 输入格式

输入 JSON 文件应符合以下格式：

```json
[
  {
    "id": "animals",
    "name": "Animals",
    "words": [
      { "id": "lion", "name": "Lion" },
      { "id": "dog", "name": "Dog" }
    ]
  }
]
```

## 输出

生成的音频文件命名规则：
- `{id}_normal.wav` - 正常语速
- `{id}_slow.wav` - 慢速语速

如果文件已存在，会自动跳过（仅生成缺失的版本）。

## 依赖

- Node.js >= 18.0.0
- commander - 参数解析
- got - HTTP 客户端
- hpagent - 代理支持

## 许可

MIT

