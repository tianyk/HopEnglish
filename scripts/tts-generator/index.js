#!/usr/bin/env node
/**
 * HopEnglish TTS Generator
 * 批量生成单词音频（Normal / Slow）
 */

'use strict';

const fs = require('node:fs');
const fsp = require('node:fs/promises');
const path = require('node:path');
const { program } = require('commander');
const got = require('got');
const { HttpsProxyAgent } = require('hpagent');

const DEFAULT_MODEL_ID = 'gemini-2.5-flash-preview-tts';
const DEFAULT_VOICE_NAME = 'Sulafat';
const DEFAULT_ACCENT = 'General American English';
const DEFAULT_TEMPERATURE = 1;
const REQUEST_TIMEOUT_MS = 120000;
const REQUEST_DELAY_MS = 2000; // 每个请求之间延迟 2 秒，避免触发速率限制
const MAX_RETRY_ATTEMPTS = 3; // 最大重试次数

// 配置 Commander
program
  .name('tts-generator')
  .description('批量生成单词音频（Normal / Slow）')
  .version('1.0.0')
  .requiredOption('--api-key <key>', 'Gemini API Key（或通过环境变量 GEMINI_API_KEY）', process.env.GEMINI_API_KEY)
  .requiredOption('--input <path>', '输入 JSON 文件路径', '../../assets/data/categories.json')
  .requiredOption('--output <path>', '输出目录路径', '../../assets/audio/words')
  .option('--model <id>', '模型 ID', DEFAULT_MODEL_ID)
  .option('--voice <name>', '语音名称', DEFAULT_VOICE_NAME)
  .option('--accent <desc>', '口音描述', DEFAULT_ACCENT)
  .option('--temperature <n>', '温度', parseFloat, DEFAULT_TEMPERATURE)
  .option('--dry-run', '只打印计划，不请求 API、不写文件', false);

program.parse();
const options = program.opts();

/**
 * @returns {string | null}
 */
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

/**
 * @param {number} ms
 * @returns {Promise<void>}
 */
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * 从错误响应中提取重试等待时间（秒）
 * @param {string} errorMessage
 * @returns {number | null}
 */
function extractRetryAfterSeconds(errorMessage) {
  const match = errorMessage.match(/retry in ([\d.]+)s/i);
  if (match && match[1]) {
    return parseFloat(match[1]);
  }
  return null;
}

/**
 * @param {string} targetUrl
 * @param {unknown} jsonBody
 * @param {number} retryAttempt
 * @returns {Promise<unknown>}
 */
async function postJson(targetUrl, jsonBody, retryAttempt = 0) {
  const proxyUrl = getProxyFromEnv();

  const gotOptions = {
    json: jsonBody,
    responseType: 'json',
    timeout: {
      request: REQUEST_TIMEOUT_MS,
    },
    headers: {
      'Content-Type': 'application/json',
    },
  };

  if (proxyUrl) {
    gotOptions.agent = {
      https: new HttpsProxyAgent({
        keepAlive: true,
        keepAliveMsecs: 1000,
        maxSockets: 256,
        maxFreeSockets: 256,
        scheduling: 'lifo',
        proxy: proxyUrl,
      }),
    };
  }

  try {
    const response = await got.post(targetUrl, gotOptions);
    return response.body;
  } catch (err) {
    if (err.response && err.response.statusCode === 429) {
      // 429 速率限制：尝试自动重试
      const status = err.response.statusCode;
      const body = err.response.body;
      const errorMsg = body?.error?.message || JSON.stringify(body);
      
      if (retryAttempt < MAX_RETRY_ATTEMPTS) {
        const retryAfter = extractRetryAfterSeconds(errorMsg);
        const waitSeconds = retryAfter || 30; // 默认等待 30 秒
        console.log(`  ⚠️  遇到速率限制（429），等待 ${waitSeconds.toFixed(1)} 秒后重试...（尝试 ${retryAttempt + 1}/${MAX_RETRY_ATTEMPTS}）`);
        await sleep(waitSeconds * 1000);
        return postJson(targetUrl, jsonBody, retryAttempt + 1);
      }
      
      throw new Error(`Gemini API 请求失败：HTTP ${status}\n${errorMsg.slice(0, 500)}`);
    }
    
    if (err.response) {
      const status = err.response.statusCode;
      const body = err.response.body;
      const errorMsg = body?.error?.message || JSON.stringify(body).slice(0, 500);
      throw new Error(`Gemini API 请求失败：HTTP ${status}\n${errorMsg}`);
    }
    throw new Error(`请求失败：${err.message}`);
  }
}

/**
 * @param {string} word
 * @param {string} accent
 * @returns {string}
 */
function buildNormalPromptInEnglish(word, accent) {
  return `You are a professional voice actor for preschool kids (age 2-5).
Your goal is to help a child map "image = sound" with maximum clarity and consistency.

TARGET WORD:
${word}

PRONUNCIATION RULES:
- Speak ONLY the target word. No extra words.
- One clean pronunciation. No repetitions.
- Keep the same voice identity across all recordings (same timbre, mood, loudness).

DIRECTOR'S NOTES
Style: Warm, cheerful, supportive. A gentle "vocal smile". Like praising a child during a fun game.
Accent: ${accent}
Pacing: Natural, clear, not rushed.
Articulation: Very clear consonants, clean vowels, natural stress. No mumbling.
Energy: Medium-high, positive, calm excitement.
Audio: Close-mic clarity, no background noise, no reverb.

OUTPUT:
Return audio only.`;
}

/**
 * @param {string} word
 * @param {string} accent
 * @returns {string}
 */
function buildSlowPromptInEnglish(word, accent) {
  return `You are a professional voice actor for preschool kids (age 2-5).
Your goal is to help a child map "image = sound" with maximum clarity and consistency.

TARGET WORD:
${word}

PRONUNCIATION RULES:
- Speak ONLY the target word. No extra words.
- One clean pronunciation. No repetitions.
- Keep the same voice identity across all recordings (same timbre, mood, loudness).

DIRECTOR'S NOTES
Style: Warm, cheerful, supportive. A gentle "vocal smile". Like praising a child during a fun game.
Accent: ${accent}
Pacing: Slow, extra clear, with tiny natural pauses; not robotic; do not unnaturally stretch vowels.
Articulation: Very clear consonants, clean vowels, natural stress. No mumbling.
Energy: Medium-high, positive, calm excitement.
Audio: Close-mic clarity, no background noise, no reverb.

OUTPUT:
Return audio only.`;
}

/**
 * @param {{ apiKey: string, modelId: string, text: string, voiceName: string, temperature: number }} args
 * @returns {Promise<{audioBase64: string, mimeType: string | null}>}
 */
async function requestTextToSpeech(args) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${args.modelId}:generateContent?key=${args.apiKey}`;

  const body = {
    contents: [
      {
        role: 'user',
        parts: [{ text: args.text }],
      },
    ],
    generationConfig: {
      responseModalities: ['AUDIO'],
      temperature: args.temperature,
      speech_config: {
        voice_config: {
          prebuilt_voice_config: {
            voice_name: args.voiceName,
          },
        },
      },
    },
  };

  const responseData = await postJson(url, body);
  const part = responseData?.candidates?.[0]?.content?.parts?.[0];
  const inline = part?.inlineData ?? part?.inline_data;
  const audioBase64 = inline?.data;
  const mimeType =
    typeof inline?.mimeType === 'string'
      ? inline.mimeType
      : (typeof inline?.mime_type === 'string' ? inline.mime_type : null);

  if (typeof audioBase64 !== 'string' || audioBase64.length === 0) {
    throw new Error('Gemini API 返回缺少音频数据（inlineData.data）');
  }

  return { audioBase64, mimeType };
}

/**
 * @param {string | null} mimeType
 * @returns {{numChannels: number, sampleRate: number, bitsPerSample: number}}
 */
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

/**
 * @param {number} dataLength
 * @param {{numChannels: number, sampleRate: number, bitsPerSample: number}} audioOptions
 * @returns {Buffer}
 */
function createWavHeader(dataLength, audioOptions) {
  const numChannels = audioOptions.numChannels;
  const sampleRate = audioOptions.sampleRate;
  const bitsPerSample = audioOptions.bitsPerSample;
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

/**
 * @param {string} audioBase64
 * @param {string | null} mimeType
 * @returns {Buffer}
 */
function convertToWav(audioBase64, mimeType) {
  const audioOptions = parseAudioMimeType(mimeType);
  const rawBuffer = Buffer.from(audioBase64, 'base64');
  const header = createWavHeader(rawBuffer.length, audioOptions);
  return Buffer.concat([header, rawBuffer]);
}

/**
 * @param {unknown} jsonValue
 * @returns {Array<{id: string, name: string}>}
 */
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

/**
 * @param {Array<{id: string, name: string}>} words
 */
function assertUniqueWordIds(words) {
  const counts = new Map();
  for (const word of words) {
    counts.set(word.id, (counts.get(word.id) || 0) + 1);
  }
  const duplicates = [];
  for (const [id, count] of counts.entries()) {
    if (count > 1) duplicates.push(id);
  }
  if (duplicates.length > 0) {
    throw new Error(`发现重复 word id：${duplicates.join(', ')}。请确保 id 全局唯一。`);
  }
}

/**
 * @param {string} filePath
 * @returns {Promise<boolean>}
 */
async function isFileExists(filePath) {
  try {
    await fsp.access(filePath, fs.constants.F_OK);
    return true;
  } catch (err) {
    return false;
  }
}

async function main() {
  const scriptDir = path.dirname(__filename);
  const inputPath = path.resolve(scriptDir, options.input);
  const outputPath = path.resolve(scriptDir, options.output);

  const categoriesRaw = await fsp.readFile(inputPath, 'utf8');
  const categoriesJson = JSON.parse(categoriesRaw);
  const words = extractWords(categoriesJson);
  assertUniqueWordIds(words);

  await fsp.mkdir(outputPath, { recursive: true });

  console.log(`词表数量：${words.length}`);
  console.log(`输入文件：${inputPath}`);
  console.log(`输出目录：${outputPath}`);
  console.log(`模型：${options.model}`);
  console.log(`声音：${options.voice}`);
  console.log(`口音：${options.accent}`);
  if (options.dryRun) console.log('Dry Run：只打印计划，不请求 API、不写文件。');

  for (let index = 0; index < words.length; index += 1) {
    const word = words[index];
    const normalFilePath = path.join(outputPath, `${word.id}_normal.wav`);
    const slowFilePath = path.join(outputPath, `${word.id}_slow.wav`);

    const isNormalExists = await isFileExists(normalFilePath);
    const isSlowExists = await isFileExists(slowFilePath);
    if (isNormalExists && isSlowExists) {
      console.log(`[${index + 1}/${words.length}] 跳过 ${word.id}（已存在）`);
      continue;
    }

    console.log(`[${index + 1}/${words.length}] 生成 ${word.id} / ${word.name}`);
    if (options.dryRun) continue;

    if (!isNormalExists) {
      console.log(`  → 请求 API（Normal）...`);
      const prompt = buildNormalPromptInEnglish(word.name, options.accent);
      const tts = await requestTextToSpeech({
        apiKey: options.apiKey,
        modelId: options.model,
        text: prompt,
        voiceName: options.voice,
        temperature: options.temperature,
      });
      console.log(`  → 转换并保存 ${word.id}_normal.wav`);
      const wav = convertToWav(tts.audioBase64, tts.mimeType);
      await fsp.writeFile(normalFilePath, wav);
      
      // 请求之间延迟，避免触发速率限制
      if (!isSlowExists) {
        await sleep(REQUEST_DELAY_MS);
      }
    }

    if (!isSlowExists) {
      console.log(`  → 请求 API（Slow）...`);
      const prompt = buildSlowPromptInEnglish(word.name, options.accent);
      const tts = await requestTextToSpeech({
        apiKey: options.apiKey,
        modelId: options.model,
        text: prompt,
        voiceName: options.voice,
        temperature: options.temperature,
      });
      console.log(`  → 转换并保存 ${word.id}_slow.wav`);
      const wav = convertToWav(tts.audioBase64, tts.mimeType);
      await fsp.writeFile(slowFilePath, wav);
    }
    
    // 单词之间延迟，避免触发速率限制
    if (index < words.length - 1) {
      await sleep(REQUEST_DELAY_MS);
    }
  }

  console.log('完成。');
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exitCode = 1;
});

