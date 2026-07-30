#!/usr/bin/env node
/**
 * HopEnglish TTS Generator
 * 批量生成单词音频（Normal / Slow）
 * 
 * 特性：
 * - 通过 OpenRouter 调用 TTS 模型
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
const OPENROUTER_TTS_URL = 'https://openrouter.ai/api/v1/audio/speech';
const DEFAULT_MODEL_ID = 'google/gemini-3.1-flash-tts-preview';
const DEFAULT_VOICE_NAME = 'Sulafat';
const DEFAULT_ACCENT = 'General American English';

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
  .version('2.1.0')
  .requiredOption('--api-key <key>', 'OpenRouter API Key（多个用逗号分隔，或通过环境变量 OPENROUTER_API_KEY）', process.env.OPENROUTER_API_KEY)
  .requiredOption('--input <path>', '输入 JSON 文件路径', '../../assets/data/categories.json')
  .requiredOption('--output <path>', '输出目录路径', '../../assets/audio/words')
  .option('--model <id>', '模型 ID', DEFAULT_MODEL_ID)
  .option('--voice <name>', '语音名称', DEFAULT_VOICE_NAME)
  .option('--accent <desc>', '口音描述', DEFAULT_ACCENT)
  .option('--word <id-or-name>', '只生成指定单词（按 id 或英文名称精确匹配，不区分大小写）')
  .option('--variant <type>', '生成版本：normal、slow 或 both', 'both')
  .option('--force', '覆盖已存在的音频文件', false);

program.parse();
const options = program.opts();

const allowedVariants = new Set(['normal', 'slow', 'both']);
options.variant = String(options.variant).toLowerCase();
if (!allowedVariants.has(options.variant)) {
  console.error(`错误：--variant 必须是 normal、slow 或 both，当前值为 "${options.variant}"`);
  process.exit(1);
}

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

async function postAudio(url, jsonBody, apiKey) {
  const proxyUrl = getProxyFromEnv();

  const gotOptions = {
    json: jsonBody,
    responseType: 'buffer',
    timeout: {
      request: REQUEST_TIMEOUT_MS,
      connect: CONNECT_TIMEOUT_MS,
      socket: SOCKET_TIMEOUT_MS,
    },
    headers: {
      Authorization: `Bearer ${apiKey}`,
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
      if (!Buffer.isBuffer(response.body) || response.body.length === 0) {
        throw new RetryableError('OpenRouter 返回了空音频');
      }
      return {
        audioBuffer: response.body,
        mimeType: response.headers['content-type'] || 'audio/pcm',
      };
    }

    let errorBody;
    try {
      errorBody = JSON.parse(response.body.toString('utf8'));
    } catch {
      errorBody = response.body.toString('utf8');
    }
    const errorMsg =
      errorBody?.error?.message ||
      (typeof errorBody === 'string' ? errorBody : JSON.stringify(errorBody)) ||
      response.statusMessage ||
      'OpenRouter 请求失败';

    if (statusCode === 429) {
      throw new RateLimitError(errorMsg);
    }
    if (statusCode >= 500) {
      throw new RetryableError(`HTTP ${statusCode}: ${errorMsg.slice(0, 200)}`);
    }
    if (statusCode >= 400) {
      throw new FatalError(`HTTP ${statusCode}: ${errorMsg.slice(0, 500)}`, statusCode);
    }
    throw new RetryableError(`HTTP ${statusCode}: ${errorMsg.slice(0, 200)}`);
  } catch (err) {
    if (err instanceof RateLimitError || err instanceof RetryableError || err instanceof FatalError) {
      throw err;
    }
    throw new RetryableError(err.message || String(err), err);
  }
}

// ============================================================
// Prompt 构建
// ============================================================

function buildNormalPromptInEnglish(word, accent) {
  return `Synthesize speech for the transcript below.
Read only the transcript. Do not speak the instructions or add any other words.

### AUDIO PROFILE
A warm, cheerful, friendly voice for preschool children aged 2–5.

### DIRECTOR'S NOTES
Style: Encouraging, with a gentle vocal smile.
Accent: ${accent}.
Pronunciation: Clear consonants, clean vowels, and natural word stress.
Pacing: Natural speaking rate, with no deliberate pauses between syllables.
Delivery: Say the target word exactly once. No repetition or sound effects.

### TRANSCRIPT
${word}`;
}

function buildSlowPromptInEnglish(word, accent) {
  return `Synthesize speech for the transcript below.
Read only the transcript. Do not speak the instructions or audio tag, and do not add any other words.

### AUDIO PROFILE
A warm, cheerful, friendly voice for preschool children aged 2–5.

### DIRECTOR'S NOTES
Style: Encouraging, with a gentle vocal smile.
Accent: ${accent}.
Pronunciation: Clear consonants, clean vowels, and natural word stress.
Pacing: Noticeably slower than normal, but still natural. Do not stretch vowels or add pauses between syllables.
Delivery: Say the target word exactly once. No repetition or sound effects.

### TRANSCRIPT
[very slow] ${word}`;
}

// ============================================================
// TTS 请求（核心：无限重试逻辑）
// ============================================================

async function requestTextToSpeech(args) {
  let retryAttempt = 0;

  while (true) {
    const currentKey = getCurrentApiKey();

    const body = {
      model: args.modelId,
      input: args.text,
      voice: args.voiceName,
      response_format: 'pcm',
    };

    try {
      return await postAudio(OPENROUTER_TTS_URL, body, currentKey);
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

function convertToWav(audioBuffer, mimeType) {
  if (audioBuffer.subarray(0, 4).toString('ascii') === 'RIFF') {
    return audioBuffer;
  }
  const audioOptions = parseAudioMimeType(mimeType);
  const header = createWavHeader(audioBuffer.length, audioOptions);
  return Buffer.concat([header, audioBuffer]);
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

function selectWord(words, query) {
  if (typeof query !== 'string' || query.trim().length === 0) return words;

  const normalizedQuery = query.trim().toLowerCase();
  const idMatch = words.find((word) => word.id.toLowerCase() === normalizedQuery);
  if (idMatch) return [idMatch];

  const nameMatch = words.find((word) => word.name.toLowerCase() === normalizedQuery);
  if (nameMatch) return [nameMatch];

  throw new Error(`词表中找不到单词 "${query}"（请使用单词 id 或完整英文名称）`);
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
  const allWords = extractWords(categoriesJson);
  const words = selectWord(allWords, options.word);
  const generateNormal = options.variant === 'normal' || options.variant === 'both';
  const generateSlow = options.variant === 'slow' || options.variant === 'both';
  const requestedVariantCount = Number(generateNormal) + Number(generateSlow);

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
  console.log(`🎚️  版本：${options.variant}`);
  if (options.word) console.log(`🎯 指定单词：${words[0].id} / ${words[0].name}`);
  if (options.force) console.log('♻️  覆盖模式：已启用');
  console.log('='.repeat(60));
  console.log('');

  const startTime = Date.now();
  let lastRequestFinishedAt = 0;

  async function generateSpeech(args) {
    if (lastRequestFinishedAt > 0) {
      const remainingDelay = REQUEST_DELAY_MS - (Date.now() - lastRequestFinishedAt);
      if (remainingDelay > 0) await sleep(remainingDelay);
    }
    try {
      return await requestTextToSpeech(args);
    } finally {
      lastRequestFinishedAt = Date.now();
    }
  }

  for (let index = 0; index < words.length; index += 1) {
    const word = words[index];
    const normalFilePath = path.join(outputPath, `${word.id}_normal.wav`);
    const slowFilePath = path.join(outputPath, `${word.id}_slow.wav`);

    const normalExists =
      generateNormal && !options.force ? await isFileExists(normalFilePath) : false;
    const slowExists =
      generateSlow && !options.force ? await isFileExists(slowFilePath) : false;

    // 检查所有请求的版本是否都已存在
    if (
      (!generateNormal || normalExists) &&
      (!generateSlow || slowExists)
    ) {
      console.log(`[${index + 1}/${words.length}] ⏭️  跳过 ${word.id}（请求的音频版本已存在）`);
      stats.skipped += requestedVariantCount;
      continue;
    }

    console.log(`[${index + 1}/${words.length}] 🎙️  生成 ${word.id} / ${word.name}`);

    // ========== 生成 Normal 版本 ==========
    if (generateNormal && !normalExists) {
      try {
        console.log(`  → [Normal] 请求 API（使用 Key #${currentKeyIndex + 1}）...`);
        const prompt = buildNormalPromptInEnglish(word.name, options.accent);
        const tts = await generateSpeech({
          modelId: options.model,
          text: prompt,
          voiceName: options.voice,
        });
        
        const wav = convertToWav(tts.audioBuffer, tts.mimeType);
        await fsp.writeFile(normalFilePath, wav);
        console.log(`  ✅ [Normal] 完成`);
        stats.success += 1;
      } catch (err) {
        console.error(`  ❌ [Normal] 失败（跳过）：${err.message}`);
        stats.failed += 1;
        stats.failedWords.push({ id: word.id, name: word.name, type: 'normal', error: err.message });
      }
    } else if (generateNormal) {
      console.log(`  ⏭️  [Normal] 跳过（已存在）`);
      stats.skipped += 1;
    }

    // ========== 生成 Slow 版本 ==========
    if (generateSlow && !slowExists) {
      try {
        console.log(`  → [Slow] 请求 API（使用 Key #${currentKeyIndex + 1}）...`);
        const prompt = buildSlowPromptInEnglish(word.name, options.accent);
        const tts = await generateSpeech({
          modelId: options.model,
          text: prompt,
          voiceName: options.voice,
        });
        
        const wav = convertToWav(tts.audioBuffer, tts.mimeType);
        await fsp.writeFile(slowFilePath, wav);
        console.log(`  ✅ [Slow] 完成`);
        stats.success += 1;
      } catch (err) {
        console.error(`  ❌ [Slow] 失败（跳过）：${err.message}`);
        stats.failed += 1;
        stats.failedWords.push({ id: word.id, name: word.name, type: 'slow', error: err.message });
      }
    } else if (generateSlow) {
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
