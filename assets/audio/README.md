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

- 生成同一个词的两版音频时，**只修改 `PACE` 段落**：
  - **Normal**：自然语速，但不赶、咬字清晰（不刻意加停顿）
  - **Slow**：必须明显更慢：用“音节边界的微停顿 + 更慢的节奏”实现，不要靠拖长元音“伪慢速”
- 建议固定同一个声音（如 **Sulafat**）与同一个口音（例如 “General American English”），全项目一致。
- 建议把生成端的 `temperature` 调低（例如 `0.2–0.4`），减少风格漂移，提升 Normal/Slow 的可对照一致性。

### 占位符说明

| 占位符 | 含义 | 示例 | 建议 |
|---|---|---|---|
| `{WORD}` | 目标单词文本（模型只读这个词，不要加其它内容） | `banana` | 每个音频只放 1 个词，避免多词串读 |
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
You are a professional voice actor for preschool kids (age 2-5).
Speak ONLY the target word, once.

TARGET WORD:
{WORD}

GLOBAL CONSISTENCY (must follow):
- Same voice identity, mood, loudness across all words and all recordings.
- No extra words, no repetition, no sound effects.
- Natural pronunciation for this accent: {ACCENT}.

DIRECTOR'S NOTES (delivery — important):
- Tone: Warm, cheerful, encouraging. A gentle "vocal smile".
- Intonation: Bright, playful, slightly animated (kid-friendly). Avoid monotone.
- Energy: Medium-high, positive, calm excitement. Not shouting.
- Audio: Close-mic clarity, no reverb, no background noise.

PACE (NORMAL):
- One natural, clear pronunciation.
- Do NOT add deliberate pauses between syllables.
- Do NOT slow down intentionally.

ARTICULATION:
- Very clear consonants, clean vowels, natural stress.
- No mumbling.

OUTPUT:
Return audio only.
```

### 模板（Normal，中文提示词）

```
你是一位面向 2-5 岁幼儿的专业配音演员。
你的目标是帮助孩子建立“图像 = 声音”的稳定映射，要求发音清晰、风格一致、可重复。

目标单词：
{WORD}

发音规则：
- 只读“目标单词”，不要添加任何其它词语或解释。
- 只读一遍，干净利落，不要重复。
- 所有录音保持同一个声音身份（音色、情绪、响度一致）。

全局一致性（必须遵守）：
- 所有单词、所有录音保持同一个声音身份（音色、情绪、响度一致）。
- 不要添加任何额外词语，不要重复，不要加入音效。
- 口音：{ACCENT}（请具体，例如“美式英语-通用”）

导演备注（语调/情绪 —— 很重要）：
- 语气：温暖、开心、鼓励；带“微笑音色”。
- 语调：明亮、童趣、略带起伏（更像在陪孩子玩），避免平铺直叙/播报腔。
- 能量：中等偏高，积极但不吵闹。
- 音频：近讲清晰，无混响，无背景噪音。

节奏（Normal）：
- 自然且清晰地读一遍。
- 不要刻意在音节之间停顿。
- 不要刻意放慢。

咬字：
- 辅音清晰、元音干净、重音自然；不要含糊。

输出要求：
只输出音频。
```

### 模板（Slow）

```
You are a professional voice actor for preschool kids (age 2-5).
Speak ONLY the target word, once.

TARGET WORD:
{WORD}

GLOBAL CONSISTENCY (must follow):
- Keep the same voice identity, mood, loudness, and delivery defined below. Only change pacing per PACE (SLOW).
- No extra words, no repetition, no sound effects.
- Same accent: {ACCENT}.

DIRECTOR'S NOTES (delivery — important):
- Tone: Warm, cheerful, encouraging. A gentle "vocal smile".
- Intonation: Bright, playful, slightly animated (kid-friendly). Avoid monotone.
- Energy: Medium-high, positive, calm excitement. Not shouting.
- Audio: Close-mic clarity, no reverb, no background noise.

PACE (SLOW) — must be noticeably slow:
- Keep natural stress, but slow the tempo to about 70% of normal speaking rate.
- Add tiny, natural micro-pauses at syllable boundaries (about 100–180 ms each).
- Target total spoken word duration:
  - 1-syllable word: ~0.8–1.0s
  - 2-syllable word: ~1.1–1.4s
  - 3+ syllables: ~1.4–1.8s
- Do NOT unnaturally stretch vowels. Use pauses + slower consonant transitions instead.
- IF the word has 1 syllable:
  - Add a brief lead-in pause (~120 ms) before speaking.

ARTICULATION:
- Extra clear consonants, clean vowels, no mumbling.

OUTPUT:
Return audio only.
```

### 模板（Slow，中文提示词）

```
你是一位面向 2-5 岁幼儿的专业配音演员。
你的目标是帮助孩子建立“图像 = 声音”的稳定映射，要求发音清晰、风格一致、可重复。

目标单词：
{WORD}

发音规则：
- 只读“目标单词”，不要添加任何其它词语或解释。
- 只读一遍，干净利落，不要重复。
- 所有录音保持同一个声音身份（音色、情绪、响度一致）。

全局一致性（必须遵守）：
- 保持下方“导演备注”定义的声音人设不变（音色、情绪、响度、语调与能量一致）；Slow 只允许按“节奏（Slow）”改变语速与微停顿。
- 不要添加任何额外词语，不要重复，不要加入音效。
- 口音：{ACCENT}（请具体，例如“美式英语-通用”）

导演备注（语调/情绪 —— 很重要）：
- 语气：温暖、开心、鼓励；带“微笑音色”。
- 语调：明亮、童趣、略带起伏（更像在陪孩子玩），避免平铺直叙/播报腔。
- 能量：中等偏高，积极但不吵闹。
- 音频：近讲清晰，无混响，无背景噪音。

节奏（Slow）——必须明显慢：
- 保持自然重音与韵律，但把整体语速降低到“大约正常语速的 70%”。
- 在“音节边界”加入非常轻微的自然停顿（每处约 100–180ms）。
- 目标总时长（仅作节奏参考，不要机械拖音）：
  - 1 音节词：约 0.8–1.0s
  - 2 音节词：约 1.1–1.4s
  - 3+ 音节词：约 1.4–1.8s
- 不要不自然地把元音拉长；优先用“更慢的节奏 + 音节微停顿 + 更慢的辅音过渡”实现慢速。
- 如果是 1 音节词：
  - 在开口前加入一个很短的“起始停顿”（约 120ms），保证听感上更慢、更可区分。

咬字：
- 辅音更清晰、元音更干净；不要含糊。

输出要求：
只输出音频。
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
