import fs from 'node:fs/promises';
import path from 'node:path';

export async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, 'utf8'));
}

export async function writeJsonAtomic(filePath, value) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  const tempPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  await fs.writeFile(tempPath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  await fs.rename(tempPath, filePath);
}

export async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

export function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function parseCliJson(output) {
  const clean = String(output)
    .replace(/\u001B\[[0-?]*[ -/]*[@-~]/g, '')
    .trim();
  if (!clean) throw new Error('Dreamina CLI 没有返回 JSON');

  for (let index = 0; index < clean.length; index += 1) {
    if (clean[index] !== '{' && clean[index] !== '[') continue;
    try {
      return JSON.parse(clean.slice(index));
    } catch {
      // CLI may print logs before JSON. Continue looking for the next opening token.
    }
  }
  throw new Error(`无法解析 Dreamina CLI JSON：${clean.slice(0, 300)}`);
}

export function parseArgs(argv) {
  const options = {
    force: false,
    candidate: false,
    acceptCandidates: false,
    applyImages: false,
    limit: undefined,
    category: undefined,
    words: [],
  };

  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === '-f' || value === '--force') options.force = true;
    else if (value === '--candidate') options.candidate = true;
    else if (value === '--accept-candidates') options.acceptCandidates = true;
    else if (value === '--apply-images') options.applyImages = true;
    else if (value === '--limit') options.limit = parsePositiveInt(argv[++index], '--limit');
    else if (value.startsWith('--limit=')) options.limit = parsePositiveInt(value.split('=')[1], '--limit');
    else if (value === '--category') options.category = requiredValue(argv[++index], '--category');
    else if (value.startsWith('--category=')) options.category = requiredValue(value.split('=')[1], '--category');
    else if (value === '--word') options.words.push(requiredValue(argv[++index], '--word'));
    else if (value.startsWith('--word=')) options.words.push(requiredValue(value.split('=')[1], '--word'));
    else if (value === '--words') options.words.push(...parseWordList(argv[++index]));
    else if (value.startsWith('--words=')) options.words.push(...parseWordList(value.slice('--words='.length)));
    else throw new Error(`未知参数：${value}`);
  }
  options.words = [...new Set(options.words)];
  return options;
}

function parsePositiveInt(value, flag) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`${flag} 必须是正整数`);
  }
  return parsed;
}

function requiredValue(value, flag) {
  if (!value) throw new Error(`${flag} 缺少值`);
  return value;
}

function parseWordList(value) {
  const words = requiredValue(value, '--words')
    .split(',')
    .map((word) => word.trim())
    .filter(Boolean);
  if (words.length === 0) throw new Error('--words 缺少值');
  return words;
}

export class Semaphore {
  #available;
  #waiters = [];

  constructor(size) {
    if (!Number.isInteger(size) || size < 1) throw new Error('Semaphore size 必须大于 0');
    this.#available = size;
  }

  async use(operation) {
    await this.#acquire();
    try {
      return await operation();
    } finally {
      this.#release();
    }
  }

  #acquire() {
    if (this.#available > 0) {
      this.#available -= 1;
      return Promise.resolve();
    }
    return new Promise((resolve) => this.#waiters.push(resolve));
  }

  #release() {
    const next = this.#waiters.shift();
    if (next) next();
    else this.#available += 1;
  }
}
