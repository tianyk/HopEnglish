# HopEnglish TTS Generator

通过 OpenRouter 的 OpenAI 兼容 TTS API，批量生成单词音频（Normal / Slow）。

默认模型为 `google/gemini-3.1-flash-tts-preview`，输出为 24 kHz / 16-bit / mono WAV。

## 安装

```bash
cd scripts/tts-generator
npm install
```

## 使用

### 基本用法

```bash
# 使用环境变量提供 API Key
OPENROUTER_API_KEY="your-key" node index.js

# 或通过参数提供
node index.js --api-key "your-key"
```

### 选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--api-key <key>` | OpenRouter API Key（必填，或通过环境变量 `OPENROUTER_API_KEY`） | - |
| `--input <path>` | 输入 JSON 文件路径 | `../../assets/data/categories.json` |
| `--output <path>` | 输出目录路径 | `../../assets/audio/words` |
| `--model <id>` | OpenRouter 模型 ID | `google/gemini-3.1-flash-tts-preview` |
| `--voice <name>` | 语音名称 | `Sulafat` |
| `--accent <desc>` | 口音描述 | `General American English` |
| `--word <id-or-name>` | 只生成指定单词，按 id 或英文名称精确匹配（不区分大小写） | - |
| `--variant <type>` | 生成 `normal`、`slow` 或 `both` | `both` |
| `--force` | 覆盖已经存在的目标音频 | `false` |
| `-h, --help` | 显示帮助 | - |
| `-V, --version` | 显示版本 | - |

### 示例

```bash
# 使用默认配置
OPENROUTER_API_KEY="your-key" node index.js

# 使用英式口音
OPENROUTER_API_KEY="your-key" node index.js --accent "British English - Received Pronunciation (RP)"

# 使用不同的语音
OPENROUTER_API_KEY="your-key" node index.js --voice "Kore"

# 只生成 banana 的 Normal 和 Slow 音频
OPENROUTER_API_KEY="your-key" node index.js --word banana

# 只重新生成 banana 的 Slow 音频
OPENROUTER_API_KEY="your-key" node index.js \
  --word banana \
  --variant slow \
  --force

# 自定义输入输出路径
node index.js --api-key "your-key" \
  --input "/path/to/input.json" \
  --output "/path/to/output"
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `OPENROUTER_API_KEY` | OpenRouter API Key（必填） |
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
