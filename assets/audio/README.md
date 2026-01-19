# 音频资源

## 目录结构

```
audio/
└── celebrations/     # 庆祝表扬语音
    ├── great.wav
    ├── well_done.wav
    ├── good_job.wav
    ├── awesome.wav
    └── yay.wav
```

## 录音要求

| 要求 | 说明 |
|------|------|
| 时长 | 1-2 秒 |
| 语速 | 稍慢，清晰 |
| 语调 | 欢快、积极、夸张一点 |
| 声音 | 温暖友好（女声/童声效果更好） |
| 格式 | WAV 或 MP3，44.1kHz |

## TTS 生成工具

推荐使用 Google AI Studio 生成语音：

🔗 https://aistudio.google.com/generate-speech?hl=zh-cn

### 推荐配置

| 参数 | 值 |
|------|-----|
| 声音 | **Sulafat** |
| 语言 | English |

## 单词配音：通用提示词模板（Normal / Slow）

> 目标：为 2-5 岁幼儿提供“清晰、稳定、可重复”的发音反馈。
> 要求：同一个词生成两版音频（Normal / Slow），除“语速”外其余风格保持一致，避免风格漂移导致孩子混淆。

### 使用方式

- 生成同一个词的两版音频时，建议直接分别使用下方 **Normal / Slow** 两套模板（除 `{WORD}` / `{ACCENT}` 外尽量不要改动），以保证风格一致与稳定性。
  - **Normal**：自然语速、清晰、不刻意放慢或加停顿
  - **Slow**：明显更慢但仍自然；**不允许拖长元音/拖尾**，也不允许在词/短语内部插入可听见停顿
- 建议固定同一个声音（如 **Sulafat**）与同一个口音（例如 “General American English”），全项目一致。
- 建议把生成端的 `temperature` 调低（例如 `0.2–0.4`），减少风格漂移，提升 Normal/Slow 的可对照一致性。

### 占位符说明

| 占位符 | 含义 | 示例 | 建议 |
|---|---|---|---|
| `{WORD}` | 目标单词文本（模型只读这个词，不要加其它内容） | `banana` | 强烈建议用“明确边界”的包裹方式传入（例如 `<target_word>{WORD}</target_word>`），避免和正文混在一起 |
| `{ACCENT}` | 口音/发音体系（决定用哪种英语在读） | `General American English` | 全项目固定一个，保证风格与发音一致性 |
| `{STRESS}` |（可选）重音/音节拆分提示 | `ba-NA-na` | 仅在模型读错/重音不稳时添加 |
| `{IPA}` |（可选）国际音标 | `/bəˈnænə/` | 仅对少数易错词使用，避免增加维护成本 |
| `{NOTES}` |（可选）额外发音约束（简短） | `clear final /t/` | 只写影响清晰度的关键点，不要改风格 |

### `{ACCENT}` 可选项（常用口音参考）

> 说明：`{ACCENT}` 是**自然语言描述**，并不是固定枚举。下面列出常用、易理解、适合儿童启蒙的一组选项；你也可以写得更具体（例如加上城市/地区），但建议全项目只选一个并长期固定。

| 口音类别 | 推荐写法（可直接填入 `{ACCENT}`） | 备注 |
|---|---|---|
| 美式 | `General American English` | 最通用的美音表达 |
| 美式 | `American English - California` | 更具体的地区描述（可选） |
| 英式 | `British English - Received Pronunciation (RP)` | “标准英音/播音腔”，清晰稳定 |
| 英式 | `British English - London` | 更具体的地区描述（可选） |
| 加拿大 | `Canadian English` | 口音接近美式，差异较小 |
| 澳大利亚 | `Australian English` | 明显不同于美/英式，慎选后要长期一致 |
| 新西兰 | `New Zealand English` | 同上 |
| 爱尔兰 | `Irish English` | 差异较明显，慎选 |
| 苏格兰 | `Scottish English` | 差异较明显，慎选 |
| 印度 | `Indian English` | 差异较明显，慎选 |
| 南非 | `South African English` | 差异较明显，慎选 |

### 模板（Normal）

```
You are recording a single-word TTS clip for preschool kids (age 2-5).

Say ONLY the target word exactly once. No extra words. No repetition. No sound effects.
Read ONLY the text inside <target_word>. Do NOT read the tags.

<target_word>{WORD}</target_word>

Accent: {ACCENT}

Delivery:
- Voice timbre is set by the TTS voice parameter; keep delivery stable with steady mood and loudness.
- Warm, cheerful, encouraging. A gentle "vocal smile".
- Close-mic clarity. No background noise. No reverb.
- Clear consonants, clean vowels. No mumbling.

Pacing (NORMAL):
- Natural speaking rate. One continuous utterance.
- No deliberate pauses between syllables.

Duration (HARD LIMITS):
- Total audio MUST be <= 1.2 seconds (including silence).
- Silence at start <= 0.08 seconds.
- Silence at end <= 0.10 seconds.

Output: audio only.
```

### 模板（Normal，中文提示词）

```
你正在为 2-5 岁幼儿录制“单词 TTS 音频”。

只读目标单词，且只读一遍：不要添加其它词语、不要重复、不要音效。
只读取 `<target_word>` 标签内的文本，不要读出标签本身。

<target_word>{WORD}</target_word>

口音：{ACCENT}

声音与风格：
- 音色由 TTS 的 voice 参数决定；这里仅约束情绪、语气与响度保持稳定，不要刻意变化。
- 温暖、开心、鼓励，带“微笑音色”。
- 近讲清晰：无背景噪音、无混响。
- 辅音清晰、元音干净，不要含糊。

语速（Normal）：
- 自然语速，一口气连贯读完。
- 不要刻意在音节之间停顿。

时长（硬约束）：
- 总音频时长必须 <= 1.2 秒（包含静音）。
- 开头静音 <= 0.08 秒。
- 结尾静音 <= 0.10 秒。

输出：只输出音频。
```

### 模板（Slow）

```
You are recording a single-word (or short-phrase) TTS clip for preschool kids (age 2-5).

Say ONLY the target word exactly once. No extra words. No repetition. No sound effects.
Read ONLY the text inside <target_word>. Do NOT read the tags.

<target_word>{WORD}</target_word>

Accent: {ACCENT}

Delivery:
- Voice timbre is set by the TTS voice parameter; keep delivery stable with steady mood and loudness.
- Warm, cheerful, encouraging. A gentle "vocal smile".
- Close-mic clarity. No background noise. No reverb.
- Clear consonants, clean vowels. No mumbling.

Pacing (SLOW, controlled):
- Clearly slower than a natural speaking rate (about 0.85x) but still natural.
- One continuous utterance. Do NOT add pauses inside the word/phrase.
- Do NOT stretch vowels or prolong any sound (no drawn-out ending).

Duration (HARD LIMITS):
- Total audio MUST be <= 1.6 seconds (including silence).
- Silence at start <= 0.10 seconds.
- Silence at end <= 0.12 seconds.

Output: audio only.
```

### 模板（Slow，中文提示词）

```
你正在为 2-5 岁幼儿录制“单词/短语 TTS 音频（Slow 版）”。

只读目标单词，且只读一遍：不要添加其它词语、不要重复、不要音效。
只读取 `<target_word>` 标签内的文本，不要读出标签本身。

<target_word>{WORD}</target_word>

口音：{ACCENT}

声音与风格：
- 音色由 TTS 的 voice 参数决定；这里仅约束情绪、语气与响度保持稳定，不要刻意变化。
- 温暖、开心、鼓励，带“微笑音色”。
- 近讲清晰：无背景噪音、无混响。
- 辅音清晰、元音干净，不要含糊。

语速（Slow，受控）：
- 比自然语速明显更慢（约 0.85x），但仍然自然。
- 一口气连贯读完：不要在词/短语内部插入可听见停顿。
- 严禁拖长元音或任何声音的尾巴（不要拖尾）。

时长（硬约束）：
- 总音频时长必须 <= 1.6 秒（包含静音）。
- 开头静音 <= 0.10 秒。
- 结尾静音 <= 0.12 秒。

输出：只输出音频。
```

### （可选）词级覆盖：仅对少数“容易读错”的词启用

> 不要为每个词重写整套提示词；优先使用通用模板，只有在模型读错或重音不稳时才加这一小段，避免破坏“风格一致性”。

```
WORD OVERRIDES (only if needed):
- Stress: {STRESS}   # e.g., "ba-NA-na"
- IPA: {IPA}         # optional
- Notes: {NOTES}     # e.g., "clear final /t/, no extra schwa"
```

## 文件列表与提示词

### 1. `great.mp3`

| 项目 | 内容 |
|------|------|
| 文本 | "Great!" |
| 情感 | 短促、惊喜、有力 |

**提示词：**
```
用兴奋欢快的女声说 "Great!"，像游戏通关后的庆祝，
语调短促有力、上扬，充满惊喜，像在为小朋友欢呼喝彩。
```

### 2. `well_done.mp3`

| 项目 | 内容 |
|------|------|
| 文本 | "Well done!" |
| 情感 | 上扬、活力、庆祝 |

**提示词：**
```
用兴奋欢快的女声说 "Well done!"，像游戏通关后的庆祝，
语调上扬，充满活力，像在为小朋友欢呼喝彩。
```

### 3. `good_job.mp3`

| 项目 | 内容 |
|------|------|
| 文本 | "Good job!" |
| 情感 | 温暖、鼓励、肯定 |

**提示词：**
```
用兴奋欢快的女声说 "Good job!"，像游戏通关后的庆祝，
语调温暖又有活力，充满鼓励，像在为小朋友竖大拇指。
```

### 4. `awesome.mp3`

| 项目 | 内容 |
|------|------|
| 文本 | "Awesome!" |
| 情感 | 拉长、惊叹、佩服 |

**提示词：**
```
用兴奋欢快的女声说 "Awesome!"，像游戏通关后的庆祝，
"Awe-" 稍微拉长，"-some!" 上扬有力，充满惊叹，像看到了很厉害的事情。
```

### 5. `yay.mp3`

| 项目 | 内容 |
|------|------|
| 文本 | "Yay!" |
| 情感 | 高音、欢呼、纯开心 |

**提示词：**
```
用兴奋欢快的女声说 "Yay!"，像游戏通关后的庆祝，
音调高、欢快，像小朋友一起欢呼，纯粹的开心。
```
