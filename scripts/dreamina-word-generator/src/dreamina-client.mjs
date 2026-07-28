import { spawn } from 'node:child_process';
import { GENERATION } from './config.mjs';
import { parseCliJson, Semaphore } from './utils.mjs';

export class DreaminaClient {
  constructor({ executable = 'dreamina', concurrency = GENERATION.cliConcurrency } = {}) {
    this.executable = executable;
    this.semaphore = new Semaphore(concurrency);
  }

  userCredit() {
    return this.#json(['user_credit']);
  }

  submitTextToImage(task) {
    return this.#json([
      'text2image',
      `--model_version=${GENERATION.modelVersion}`,
      `--ratio=${GENERATION.ratio}`,
      `--resolution_type=${GENERATION.resolution}`,
      '--poll=0',
      `--prompt=${task.prompt}`,
    ], { timeoutMs: 120_000 });
  }

  query(submitId) {
    return this.#json(['query_result', `--submit_id=${submitId}`], { timeoutMs: 30_000 });
  }

  listTasks({ limit = 100, offset = 0 } = {}) {
    return this.#json(['list_task', `--limit=${limit}`, `--offset=${offset}`], { timeoutMs: 30_000 });
  }

  async #json(args, options) {
    const result = await this.#run(args, options);
    return parseCliJson(result.stdout);
  }

  #run(args, { timeoutMs = 30_000 } = {}) {
    return this.semaphore.use(() => new Promise((resolve, reject) => {
      const child = spawn(this.executable, args, {
        shell: false,
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      let stdout = '';
      let stderr = '';
      let timedOut = false;
      const timeout = setTimeout(() => {
        timedOut = true;
        child.kill('SIGTERM');
      }, timeoutMs);

      child.stdout.setEncoding('utf8');
      child.stderr.setEncoding('utf8');
      child.stdout.on('data', (chunk) => { stdout += chunk; });
      child.stderr.on('data', (chunk) => { stderr += chunk; });
      child.on('error', (error) => {
        clearTimeout(timeout);
        reject(error);
      });
      child.on('close', (code, signal) => {
        clearTimeout(timeout);
        if (code === 0 && !timedOut) {
          resolve({ stdout, stderr });
          return;
        }
        const error = new Error(
          timedOut
            ? `Dreamina CLI 超时：${args[0]}`
            : `Dreamina CLI 失败（code=${code}, signal=${signal ?? 'none'}）：${stderr || stdout}`,
        );
        error.stdout = stdout;
        error.stderr = stderr;
        error.exitCode = code;
        reject(error);
      });
    }));
  }
}

export function interpretQueryResult(result) {
  const status = String(result?.gen_status ?? '').toLowerCase();
  const failReason = result?.fail_reason ?? '';
  if (status === 'success') {
    const image = result?.result_json?.images?.[0];
    if (!image?.image_url) {
      return { kind: 'failure', reason: '任务成功但没有返回图片 URL', rawStatus: status };
    }
    return {
      kind: 'success',
      imageUrl: image.image_url,
      width: image.width,
      height: image.height,
      creditCount: Number(result.credit_count ?? 0),
      rawStatus: status,
    };
  }
  if (failReason || /fail|error|cancel|reject/.test(status)) {
    return { kind: 'failure', reason: failReason || `Dreamina 状态：${status}`, rawStatus: status };
  }
  return { kind: 'pending', rawStatus: status || 'unknown' };
}

export function findMatchingRemoteTask(prompt, remoteTasks) {
  const matches = remoteTasks.filter((task) => task.prompt === prompt && task.submit_id);
  if (matches.length === 0) return null;
  return matches.find((task) => task.gen_status === 'success') ??
    matches.find((task) => task.gen_status === 'querying') ??
    matches[0];
}
