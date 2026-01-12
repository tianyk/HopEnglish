#!/usr/bin/env node
/**
 * HopEnglish TTS Generator
 * 批量生成单词音频（Normal / Slow）
 * 
 * 特性：
 * - 支持多个 API Key 轮换
 * - 智能错误处理，无人值守运行
 * - 自动重试，指数退避
 */

'use strict';

const fs = require('node:fs');
const fsp = require('node:fs/promises');
const path = require('node:path');
const { program } = require('commander');
const got = require('got');
const { HttpsProxyAgent } = require('hpagent');

// ============================================================
// 配置常量
// ============================================================
const DEFAULT_MODEL_ID = 'gemini-2.5-flash-preview-tts';
const DEFAULT_VOICE_NAME = 'Sulafat';
const DEFAULT_ACCENT = 'General American English';
const DEFAULT_TEMPERATURE = 0.3;

// 超时配置
const REQUEST_TIMEOUT_MS = 120000;
const CONNECT_TIMEOUT_MS = 30000;
const SOCKET_TIMEOUT_MS = 120000;

// 重试配置
const REQUEST_DELAY_MS = 7000; // 请求间隔 7 秒
const ALL_KEYS_EXHAUSTED_WAIT_MS = 60000; // 所有 key 耗尽后等待 60 秒
const INITIAL_RETRY_DELAY_MS = 10000; // 初始重试延迟 10 秒
const MAX_RETRY_DELAY_MS = 300000; // 最大重试延迟 5 分钟

// ============================================================
// 全局状态
// ============================================================
let apiKeys = [];
let currentKeyIndex = 0;
const keyFailureCount = new Map();

// 统计
const stats = {
  success: 0,
  skipped: 0,
  failed: 0,
  failedWords: [],
};

// ============================================================
// Commander 配置
// ============================================================
program
  .name('tts-generator')
  .description('批量生成单词音频（Normal / Slow）')
  .version('1.0.0')
  .requiredOption('--api-key <key>', 'Gemini API Key（多个用逗号分隔，或通过环境变量 GEMINI_API_KEY）', process.env.GEMINI_API_KEY)
  .requiredOption('--input <path>', '输入 JSON 文件路径', '../../assets/data/categories.json')
  .requiredOption('--output <path>', '输出目录路径', '../../assets/audio/words/v2')
  .option('--model <id>', '模型 ID', DEFAULT_MODEL_ID)
  .option('--voice <name>', '语音名称', DEFAULT_VOICE_NAME)
  .option('--accent <desc>', '口音描述', DEFAULT_ACCENT)
  .option('--temperature <n>', '温度', parseFloat, DEFAULT_TEMPERATURE);

program.parse();
const options = program.opts();

// 解析多个 API keys
if (typeof options.apiKey === 'string') {
  apiKeys = options.apiKey.split(',').map(key => key.trim()).filter(key => key.length > 0);
  if (apiKeys.length === 0) {
    console.error('错误：未提供有效的 API Key');
    process.exit(1);
  }
  console.log(`已加载 ${apiKeys.length} 个 API Key`);
  apiKeys.forEach((_, index) => keyFailureCount.set(index, 0));
} else {
  console.error('错误：未提供 API Key');
  process.exit(1);
}

// ============================================================
// 错误类型定义
// ============================================================

/** 429 速率限制错误 */
class RateLimitError extends Error {
  constructor(message) {
    super(message);
    this.name = 'RateLimitError';
  }
}

/** 可重试错误（网络、5xx、超时等） */
class RetryableError extends Error {
  constructor(message, originalError = null) {
    super(message);
    this.name = 'RetryableError';
    this.originalError = originalError;
  }
}

/** 致命错误（400、401、403 等，不可重试） */
class FatalError extends Error {
  constructor(message, statusCode = null) {
    super(message);
    this.name = 'FatalError';
    this.statusCode = statusCode;
  }
}

// ============================================================
// API Key 管理
// ============================================================

function getCurrentApiKey() {
  return apiKeys[currentKeyIndex];
}

function rotateToNextApiKey() {
  const previousIndex = currentKeyIndex;
  currentKeyIndex = (currentKeyIndex + 1) % apiKeys.length;
  console.log(`  ⚡ 切换 API Key：#${previousIndex + 1} → #${currentKeyIndex + 1}`);
}

function areAllKeysFailed() {
  return Array.from(keyFailureCount.values()).every(count => count > 0);
}

function markCurrentKeyAsFailed() {
  const count = keyFailureCount.get(currentKeyIndex) || 0;
  keyFailureCount.set(currentKeyIndex, count + 1);
}

function resetAllKeyFailures() {
  apiKeys.forEach((_, index) => keyFailureCount.set(index, 0));
  console.log(`  🔄 已重置所有 API Key 的失败计数`);
}

// ============================================================
// 工具函数
// ============================================================

function getProxyFromEnv() {
  const keys = ['HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy'];
  for (const key of keys) {
    const value = process.env[key];
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim();
    }
  }
  return null;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function formatDuration(ms) {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${Math.round(ms / 1000)}s`;
  return `${Math.round(ms / 60000)}m`;
}

function calculateBackoffDelay(attempt) {
  const delay = INITIAL_RETRY_DELAY_MS * Math.pow(2, attempt);
  return Math.min(delay, MAX_RETRY_DELAY_MS);
}

// ============================================================
// HTTP 请求
// ============================================================

async function postJson(url, jsonBody) {
  const proxyUrl = getProxyFromEnv();

  const gotOptions = {
    json: jsonBody,
    responseType: 'json',
    timeout: {
      request: REQUEST_TIMEOUT_MS,
      connect: CONNECT_TIMEOUT_MS,
      socket: SOCKET_TIMEOUT_MS,
    },
    headers: {
      'Content-Type': 'application/json',
    },
    retry: { limit: 0 },
    http2: false,
    throwHttpErrors: false,
  };

  if (proxyUrl) {
    gotOptions.agent = {
      https: new HttpsProxyAgent({
        keepAlive: false,
        keepAliveMsecs: 0,
        timeout: CONNECT_TIMEOUT_MS,
        scheduling: 'lifo',
        proxy: proxyUrl,
      }),
    };
  }

  try {
    const response = await got.post(url, gotOptions);
    const statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return response.body;
    }

    const errorBody = response.body;
    const errorMsg = errorBody?.error?.message || JSON.stringify(errorBody);

    // 429 速率限制
    if (statusCode === 429) {
      throw new RateLimitError(errorMsg);
    }

    // 5xx 服务器错误 - 可重试
    if (statusCode >= 500) {
      throw new RetryableError(`HTTP ${statusCode}: ${errorMsg.slice(0, 200)}`);
    }

    // 4xx 客户端错误 - 致命（除了 429）
    if (statusCode >= 400) {
      throw new FatalError(`HTTP ${statusCode}: ${errorMsg.slice(0, 500)}`, statusCode);
    }

    throw new RetryableError(`HTTP ${statusCode}: ${errorMsg.slice(0, 200)}`);
  } catch (err) {
    if (err instanceof RateLimitError || err instanceof RetryableError || err instanceof FatalError) {
      throw err;
    }
    // 网络错误、超时等 - 可重试
    throw new RetryableError(err.message || String(err), err);
  }
}

// ============================================================
// Prompt 构建
// ============================================================

function buildNormalPromptInEnglish(word, accent) {
  return `You are a professional voice actor for preschool kids (age 2-5).
Speak ONLY the target word, once.

TARGET WORD (verbatim):
<target_word>${word}</target_word>

GLOBAL CONSISTENCY (must follow):
- Same voice identity, mood, loudness across all words and all recordings.
- No extra words, no repetition, no sound effects.
- Natural pronunciation for this accent: ${accent}.

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
Return audio only.`;
}

function buildSlowPromptInEnglish(word, accent) {
  return `You are a professional voice actor for preschool kids (age 2-5).
Speak ONLY the target word, once.

TARGET WORD (verbatim):
<target_word>${word}</target_word>

GLOBAL CONSISTENCY (must follow):
- Keep the same voice identity, mood, loudness, and delivery defined below. Only change pacing per PACE (SLOW).
- No extra words, no repetition, no sound effects.
- Same accent: ${accent}.

DIRECTOR'S NOTES (delivery — important):
- Tone: Warm, cheerful, encouraging. A gentle "vocal smile".
- Intonation: Bright, playful, slightly animated (kid-friendly). Avoid monotone.
- Energy: Medium-high, positive, calm excitement. Not shouting.
- Audio: Close-mic clarity, no reverb, no background noise.

PACE (SLOW) — must be noticeably slow:
- Keep natural stress, but slow the overall tempo to about 85–90% of normal speaking rate.
- Speak the target word/short phrase as ONE continuous utterance: no splitting into letters/phonemes.
- Do NOT insert audible pauses inside the word (avoid syllable gaps). Any pause, if needed, must be imperceptible and only between consonant transitions.
- Target total spoken word/phrase duration (upper-bounded; do not exceed):
  - 1-syllable word: ~0.6–0.9s (max 1.1s)
  - 2-syllable word: ~0.9–1.2s (max 1.4s)
  - 3+ syllables: ~1.2–1.6s (max 1.8s)
- Do NOT stretch vowels (no “D.....o..g”). Slow down using smoother, slightly slower consonant transitions while keeping vowels natural-length.
- If the target is a short phrase with spaces/hyphens (e.g., "Hot Dog", "Ice Cream", "T-shirt"):
  - Speak it naturally as ONE phrase. Spaces/hyphens are only a tiny, connected boundary — never a noticeable pause.
- Optional: add a very brief lead-in silence (~80–120 ms) BEFORE the word only (never inside the word).

ARTICULATION:
- Extra clear consonants, clean vowels, no mumbling.

OUTPUT:
Return audio only.`;
}

// ============================================================
// TTS 请求（核心：无限重试逻辑）
// ============================================================

async function requestTextToSpeech(args) {
  let retryAttempt = 0;

  while (true) {
    const currentKey = getCurrentApiKey();
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${args.modelId}:generateContent?key=${currentKey}`;

    const body = {
      contents: [{ role: 'user', parts: [{ text: args.text }] }],
      generationConfig: {
        responseModalities: ['AUDIO'],
        temperature: args.temperature,
        speech_config: {
          voice_config: {
            prebuilt_voice_config: { voice_name: args.voiceName },
          },
        },
      },
    };

    try {
      const responseData = await postJson(url, body);
      const part = responseData?.candidates?.[0]?.content?.parts?.[0];
      const inline = part?.inlineData ?? part?.inline_data;
      const audioBase64 = inline?.data;
      const mimeType =
        typeof inline?.mimeType === 'string'
          ? inline.mimeType
          : (typeof inline?.mime_type === 'string' ? inline.mime_type : null);

      if (typeof audioBase64 !== 'string' || audioBase64.length === 0) {
        throw new RetryableError('API 返回缺少音频数据');
      }

      return { audioBase64, mimeType };
    } catch (err) {
      // ========== 429 速率限制 ==========
      if (err instanceof RateLimitError) {
        console.log(`  ⚠️  API Key #${currentKeyIndex + 1} 遇到速率限制（429）`);
        markCurrentKeyAsFailed();

        if (areAllKeysFailed()) {
          console.log(`  ⏸️  所有 ${apiKeys.length} 个 API Key 均已达到速率限制`);
          console.log(`  ⏳ 等待 ${formatDuration(ALL_KEYS_EXHAUSTED_WAIT_MS)} 后重试...`);
          await sleep(ALL_KEYS_EXHAUSTED_WAIT_MS);
          resetAllKeyFailures();
        }

        rotateToNextApiKey();
        retryAttempt = 0; // 切换 key 后重置重试计数
        continue;
      }

      // ========== 致命错误（不可重试） ==========
      if (err instanceof FatalError) {
        throw err; // 向上抛出，由调用方决定是否跳过
      }

      // ========== 可重试错误 ==========
      if (err instanceof RetryableError) {
        retryAttempt += 1;
        const delay = calculateBackoffDelay(retryAttempt - 1);
        console.log(`  ⚠️  可重试错误：${err.message.slice(0, 100)}`);
        console.log(`  ⏳ 等待 ${formatDuration(delay)} 后重试...（第 ${retryAttempt} 次）`);
        await sleep(delay);
        continue;
      }

      // ========== 未知错误 - 视为可重试 ==========
      retryAttempt += 1;
      const delay = calculateBackoffDelay(retryAttempt - 1);
      console.log(`  ⚠️  未知错误：${err.message?.slice(0, 100) || err}`);
      console.log(`  ⏳ 等待 ${formatDuration(delay)} 后重试...（第 ${retryAttempt} 次）`);
      await sleep(delay);
    }
  }
}

// ============================================================
// 音频处理
// ============================================================

function parseAudioMimeType(mimeType) {
  const defaultOptions = { numChannels: 1, sampleRate: 24000, bitsPerSample: 16 };
  if (!mimeType) return defaultOptions;
  const [fileType, ...params] = mimeType.split(';').map((s) => s.trim());
  const fileTypeParts = fileType.split('/');
  const format = fileTypeParts.length >= 2 ? fileTypeParts[1] : '';
  const audioOptions = { ...defaultOptions };
  if (typeof format === 'string' && format.startsWith('L')) {
    const bits = Number.parseInt(format.slice(1), 10);
    if (Number.isFinite(bits)) audioOptions.bitsPerSample = bits;
  }
  for (const param of params) {
    const [key, value] = param.split('=').map((s) => s.trim());
    if (key === 'rate') {
      const sampleRate = Number.parseInt(value, 10);
      if (Number.isFinite(sampleRate)) audioOptions.sampleRate = sampleRate;
    }
  }
  return audioOptions;
}

function createWavHeader(dataLength, audioOptions) {
  const { numChannels, sampleRate, bitsPerSample } = audioOptions;
  const byteRate = (sampleRate * numChannels * bitsPerSample) / 8;
  const blockAlign = (numChannels * bitsPerSample) / 8;
  const buffer = Buffer.alloc(44);
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataLength, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(bitsPerSample, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataLength, 40);
  return buffer;
}

function convertToWav(audioBase64, mimeType) {
  const audioOptions = parseAudioMimeType(mimeType);
  const rawBuffer = Buffer.from(audioBase64, 'base64');
  const header = createWavHeader(rawBuffer.length, audioOptions);
  return Buffer.concat([header, rawBuffer]);
}

// ============================================================
// 数据处理
// ============================================================

function extractWords(jsonValue) {
  if (!Array.isArray(jsonValue)) throw new Error('categories.json 顶层应为数组');
  const words = [];
  for (const category of jsonValue) {
    const categoryWords = category && typeof category === 'object' ? category.words : null;
    if (!Array.isArray(categoryWords)) continue;
    for (const word of categoryWords) {
      const id = word && typeof word === 'object' ? word.id : null;
      const name = word && typeof word === 'object' ? word.name : null;
      if (typeof id !== 'string' || id.trim().length === 0) continue;
      if (typeof name !== 'string' || name.trim().length === 0) continue;
      words.push({ id: id.trim(), name: name.trim() });
    }
  }
  return words;
}

async function isFileExists(filePath) {
  try {
    await fsp.access(filePath, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

// ============================================================
// 主函数
// ============================================================

async function main() {
  const scriptDir = path.dirname(__filename);
  const inputPath = path.resolve(scriptDir, options.input);
  const outputPath = path.resolve(scriptDir, options.output);

  const categoriesRaw = await fsp.readFile(inputPath, 'utf8');
  const categoriesJson = JSON.parse(categoriesRaw);
  const words = extractWords(categoriesJson);

  await fsp.mkdir(outputPath, { recursive: true });

  console.log('');
  console.log('='.repeat(60));
  console.log('🎙️  HopEnglish TTS Generator');
  console.log('='.repeat(60));
  console.log(`📝 词表数量：${words.length}`);
  console.log(`🔑 API Keys：${apiKeys.length} 个`);
  console.log(`📂 输入文件：${inputPath}`);
  console.log(`📁 输出目录：${outputPath}`);
  console.log(`🤖 模型：${options.model}`);
  console.log(`🗣️  声音：${options.voice}`);
  console.log(`🌍 口音：${options.accent}`);
  console.log('='.repeat(60));
  console.log('');

  const startTime = Date.now();

  for (let index = 0; index < words.length; index += 1) {
    const word = words[index];
    const normalFilePath = path.join(outputPath, `${word.id}_normal.wav`);
    const slowFilePath = path.join(outputPath, `${word.id}_slow.wav`);

    const normalExists = await isFileExists(normalFilePath);
    const slowExists = await isFileExists(slowFilePath);

    // 检查是否两个文件都已存在
    if (normalExists && slowExists) {
      console.log(`[${index + 1}/${words.length}] ⏭️  跳过 ${word.id}（Normal & Slow 已存在）`);
      stats.skipped += 2;
      continue;
    }

    console.log(`[${index + 1}/${words.length}] 🎙️  生成 ${word.id} / ${word.name}`);

    // ========== 生成 Normal 版本 ==========
    if (!normalExists) {
      try {
        console.log(`  → [Normal] 请求 API（使用 Key #${currentKeyIndex + 1}）...`);
        const prompt = buildNormalPromptInEnglish(word.name, options.accent);
        const tts = await requestTextToSpeech({
          modelId: options.model,
          text: prompt,
          voiceName: options.voice,
          temperature: options.temperature,
        });
        
        const wav = convertToWav(tts.audioBase64, tts.mimeType);
        await fsp.writeFile(normalFilePath, wav);
        console.log(`  ✅ [Normal] 完成`);
        stats.success += 1;
      } catch (err) {
        console.error(`  ❌ [Normal] 失败（跳过）：${err.message}`);
        stats.failed += 1;
        stats.failedWords.push({ id: word.id, name: word.name, type: 'normal', error: err.message });
      }
      
      // 请求间隔
      await sleep(REQUEST_DELAY_MS);
    } else {
      console.log(`  ⏭️  [Normal] 跳过（已存在）`);
      stats.skipped += 1;
    }

    // ========== 生成 Slow 版本 ==========
    if (!slowExists) {
      try {
        console.log(`  → [Slow] 请求 API（使用 Key #${currentKeyIndex + 1}）...`);
        const prompt = buildSlowPromptInEnglish(word.name, options.accent);
        const tts = await requestTextToSpeech({
          modelId: options.model,
          text: prompt,
          voiceName: options.voice,
          temperature: options.temperature,
        });
        
        const wav = convertToWav(tts.audioBase64, tts.mimeType);
        await fsp.writeFile(slowFilePath, wav);
        console.log(`  ✅ [Slow] 完成`);
        stats.success += 1;
      } catch (err) {
        console.error(`  ❌ [Slow] 失败（跳过）：${err.message}`);
        stats.failed += 1;
        stats.failedWords.push({ id: word.id, name: word.name, type: 'slow', error: err.message });
      }
      
      // 请求间隔（如果不是最后一个单词）
      if (index < words.length - 1) {
        await sleep(REQUEST_DELAY_MS);
      }
    } else {
      console.log(`  ⏭️  [Slow] 跳过（已存在）`);
      stats.skipped += 1;
    }
  }

  const duration = Date.now() - startTime;

  // 打印统计
  console.log('');
  console.log('='.repeat(60));
  console.log('📊 执行统计');
  console.log('='.repeat(60));
  console.log(`✅ 成功：${stats.success}`);
  console.log(`⏭️  跳过：${stats.skipped}`);
  console.log(`❌ 失败：${stats.failed}`);
  console.log(`⏱️  耗时：${formatDuration(duration)}`);

  if (stats.failedWords.length > 0) {
    console.log('');
    console.log('❌ 失败的单词：');
    for (const item of stats.failedWords) {
      const typeLabel = item.type ? `[${item.type}]` : '';
      console.log(`   - ${item.id} (${item.name}) ${typeLabel}: ${item.error.slice(0, 80)}`);
    }
  }

  console.log('='.repeat(60));
  
  if (stats.failed === 0) {
    console.log('🎉 全部完成！');
  } else {
    console.log(`⚠️  完成，但有 ${stats.failed} 个单词失败`);
  }
  console.log('='.repeat(60));
}

main().catch((err) => {
  console.error('');
  console.error('='.repeat(60));
  console.error('💥 致命错误：', err instanceof Error ? err.message : err);
  console.error('='.repeat(60));
  process.exitCode = 1;
});
