#!/usr/bin/env node

import fs from 'node:fs/promises';
import path from 'node:path';
import { GENERATION, PATHS, STATUS } from './config.mjs';
import { DreaminaClient, findMatchingRemoteTask, interpretQueryResult } from './dreamina-client.mjs';
import { downloadOriginal, processOriginal, validateFinalImage } from './image-processor.mjs';
import { canSubmit, StateStore } from './state-store.mjs';
import {
  applyCategoryImages,
  applyImagesToCategories,
  buildCategoryIconManifest,
  buildTaskManifest,
  selectCategoryIconTasks,
  selectTasks,
} from './tasks.mjs';
import { parseArgs, pathExists, sleep, writeJsonAtomic } from './utils.mjs';

let stopping = false;
process.on('SIGINT', () => {
  if (stopping) process.exit(130);
  stopping = true;
  console.log('\n停止提交新任务，等待当前操作结束……');
});

main().catch((error) => {
  console.error(error.stack ?? error.message);
  process.exitCode = 1;
});

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const manifest = options.categoryIcons
    ? await buildCategoryIconManifest()
    : await buildTaskManifest();
  const selected = options.categoryIcons
    ? selectCategoryIconTasks(manifest.tasks, options)
    : selectTasks(manifest.tasks, options);
  validateMode(options);

  if (options.acceptCandidates) {
    await acceptCandidates(selected);
    return;
  }

  const tasks = options.candidate
    ? selected.map((task) => ({
        ...task,
        outputPath: task.candidatePath ?? path.join(PATHS.candidates, task.filename),
        originalPath: task.candidateOriginalPath ??
          path.join(PATHS.candidateOriginals, task.filename),
      }))
    : selected;
  const store = await generate(manifest, tasks, options);
  if (options.applyImages) {
    const successfulJobKeys = new Set(
      manifest.tasks
        .filter((task) => store.job(task.jobKey).status === STATUS.success)
        .map((task) => task.jobKey),
    );
    const categories = options.categoryIcons
      ? applyCategoryImages(manifest.categories, manifest.tasks, successfulJobKeys)
      : applyImagesToCategories(manifest.categories, manifest.tasks, successfulJobKeys);
    await writeJsonAtomic(PATHS.categories, categories);
    console.log(`已更新 ${successfulJobKeys.size} 个图片映射`);
  }
}

async function generate(manifest, tasks, options) {
  const store = await StateStore.open(manifest.tasks);
  const client = new DreaminaClient();
  await fs.mkdir(PATHS.originals, { recursive: true });
  await fs.mkdir(PATHS.words, { recursive: true });

  await resetForGeneration(store, tasks, options.force);
  await recoverFiles(store, tasks);
  await reconcileUnknown(store, tasks, client);

  const pending = tasks.filter((task) => canSubmit(store.job(task.jobKey))).length;
  if (pending > 0) {
    const credit = await client.userCredit();
    const required = pending * GENERATION.creditsPerImage;
    if (Number(credit.total_credit) < required) {
      throw new Error(`credits 不足：需要约 ${required}，当前 ${credit.total_credit}`);
    }
    console.log(`待生成 ${pending} 张，预计使用 ${required} credits`);
  }

  const scheduler = new Scheduler(store, client, tasks);
  await scheduler.run();
  await store.flush();
  printSummary(store, tasks);
  return store;
}

function validateMode(options) {
  if ((options.candidate || options.acceptCandidates) &&
      !options.categoryIcons && !options.category && !options.words.length && !options.limit) {
    throw new Error('候选模式必须使用 --word、--words、--category 或 --limit 限定范围');
  }
  if (options.candidate && options.acceptCandidates) {
    throw new Error('--candidate 与 --accept-candidates 不能同时使用');
  }
  if (options.applyImages && (options.candidate || options.acceptCandidates)) {
    throw new Error('--apply-images 不能与候选模式同时使用');
  }
}

async function acceptCandidates(tasks) {
  for (const task of tasks) {
    const candidatePath = task.candidatePath ?? path.join(PATHS.candidates, task.filename);
    const valid = await validateFinalImage(candidatePath);
    if (!valid.ok) throw new Error(`${task.jobKey} 候选图无效：${valid.error}`);
  }
  for (const task of tasks) {
    const candidatePath = task.candidatePath ?? path.join(PATHS.candidates, task.filename);
    const tempPath = `${task.outputPath}.candidate`;
    await fs.copyFile(candidatePath, tempPath);
    await fs.rename(tempPath, task.outputPath);
    console.log(`采用候选图 ${task.jobKey}`);
  }
}

async function resetForGeneration(store, tasks, force) {
  const resetTasks = tasks.filter((task) => {
    const job = store.job(task.jobKey);
    return force || (job.status === STATUS.failed && !job.resultUrl);
  });
  for (const task of resetTasks) {
    await Promise.all([
      fs.rm(task.outputPath, { force: true }),
      fs.rm(task.originalPath, { force: true }),
    ]);
    await store.update(task.jobKey, {
      status: STATUS.pending,
      submitId: null,
      resultUrl: null,
      creditCount: 0,
      failReason: null,
      nextPollAt: null,
      submittedAt: null,
      prompt: task.prompt,
      chromaKey: task.chromaKey,
    });
  }
  if (resetTasks.length > 0) {
    console.log(force
      ? `强制重新生成 ${resetTasks.length} 个任务`
      : `自动重新生成 ${resetTasks.length} 个失败任务`);
  }
  if (!force) {
    const recoverable = tasks.filter((task) => {
      const job = store.job(task.jobKey);
      return job.status === STATUS.failed && Boolean(job.resultUrl);
    });
    for (const task of recoverable) {
      await store.update(task.jobKey, {
        status: STATUS.generated,
        failReason: '复用已生成结果，重新下载或处理',
      });
    }
    if (recoverable.length > 0) {
      console.log(`复用 ${recoverable.length} 个已扣费的生成结果`);
    }
  }
}

async function recoverFiles(store, tasks) {
  for (const task of tasks) {
    if ((await validateFinalImage(task.outputPath)).ok) {
      await store.update(task.jobKey, { status: STATUS.success, failReason: null });
      continue;
    }
    const job = store.job(task.jobKey);
    if (
      await pathExists(task.originalPath) &&
      [STATUS.generated, STATUS.processing, STATUS.success].includes(job.status)
    ) {
      try {
        await store.update(task.jobKey, { status: STATUS.processing });
        await processOriginal(task);
        await store.update(task.jobKey, { status: STATUS.success, failReason: null });
      } catch (error) {
        await store.update(task.jobKey, { status: STATUS.failed, failReason: error.message });
      }
    } else if (job.status === STATUS.generated && job.resultUrl) {
      await downloadAndProcess(store, task, job.resultUrl);
    }
  }
}

async function reconcileUnknown(store, tasks, client) {
  const unknown = tasks.filter((task) => {
    const job = store.job(task.jobKey);
    return [STATUS.submitting, STATUS.submittingUnknown].includes(job.status) && !job.submitId;
  });
  if (unknown.length === 0) return;

  const remote = [];
  for (let offset = 0; offset < 2_000; offset += 100) {
    const page = await client.listTasks({ limit: 100, offset });
    remote.push(...page);
    if (page.length < 100) break;
  }
  for (const task of unknown) {
    const match = findMatchingRemoteTask(store.job(task.jobKey).prompt, remote);
    await store.update(task.jobKey, match
      ? {
          status: STATUS.querying,
          submitId: match.submit_id,
          nextPollAt: Date.now(),
          failReason: null,
        }
      : {
          status: STATUS.submittingUnknown,
          failReason: '无法确认是否已提交；为避免重复扣费，不会自动重跑',
        });
  }
}

class Scheduler {
  constructor(store, client, tasks) {
    this.store = store;
    this.client = client;
    this.tasks = tasks;
    this.submits = new Map();
    this.queries = new Map();
    this.processes = new Map();
  }

  async run() {
    while (!stopping) {
      this.launchProcessing();
      this.launchQueries();
      this.launchSubmissions();
      const active = this.active();
      if (active.length === 0 && !this.hasWork()) break;
      await (active.length ? Promise.race([Promise.race(active), sleep(500)]) : sleep(500));
    }
    await Promise.allSettled(this.active());
  }

  launchSubmissions() {
    const remoteCount = this.tasks.filter((task) =>
      [STATUS.submitting, STATUS.querying].includes(this.store.job(task.jobKey).status)).length;
    let slots = Math.min(
      GENERATION.submitConcurrency - this.submits.size,
      GENERATION.maxRemoteInFlight - remoteCount,
    );
    if (slots <= 0) return;
    for (const task of this.tasks) {
      if (slots <= 0) break;
      if (!canSubmit(this.store.job(task.jobKey)) || this.submits.has(task.jobKey)) continue;
      this.track(this.submits, task.jobKey, this.submit(task));
      slots -= 1;
    }
  }

  launchQueries() {
    let slots = GENERATION.queryConcurrency - this.queries.size;
    if (slots <= 0) return;
    for (const task of this.tasks) {
      if (slots <= 0) break;
      const job = this.store.job(task.jobKey);
      if (
        job.status !== STATUS.querying ||
        !job.submitId ||
        Number(job.nextPollAt ?? 0) > Date.now() ||
        this.queries.has(task.jobKey)
      ) continue;
      this.track(this.queries, task.jobKey, this.query(task));
      slots -= 1;
    }
  }

  launchProcessing() {
    let slots = GENERATION.processingConcurrency - this.processes.size;
    if (slots <= 0) return;
    for (const task of this.tasks) {
      if (slots <= 0) break;
      const job = this.store.job(task.jobKey);
      if (job.status !== STATUS.generated || this.processes.has(task.jobKey)) continue;
      this.track(this.processes, task.jobKey, downloadAndProcess(this.store, task, job.resultUrl));
      slots -= 1;
    }
  }

  async submit(task) {
    await this.store.update(task.jobKey, {
      status: STATUS.submitting,
      failReason: null,
      submittedAt: new Date().toISOString(),
    });
    try {
      const result = await this.client.submitTextToImage(task);
      if (!result.submit_id) throw new Error('提交结果缺少 submit_id');
      await this.store.update(task.jobKey, {
        status: STATUS.querying,
        submitId: result.submit_id,
        nextPollAt: Date.now() + GENERATION.firstPollDelayMs,
      });
      console.log(`提交 ${task.jobKey}`);
    } catch (error) {
      await this.store.update(task.jobKey, {
        status: STATUS.submittingUnknown,
        failReason: error.message,
      });
    }
  }

  async query(task) {
    const job = this.store.job(task.jobKey);
    try {
      const result = interpretQueryResult(await this.client.query(job.submitId));
      if (result.kind === 'success') {
        await this.store.update(task.jobKey, {
          status: STATUS.generated,
          resultUrl: result.imageUrl,
          creditCount: result.creditCount,
          failReason: null,
        });
        console.log(`完成 ${task.jobKey}`);
      } else if (result.kind === 'failure') {
        await this.store.update(task.jobKey, { status: STATUS.failed, failReason: result.reason });
      } else {
        await this.store.update(task.jobKey, {
          nextPollAt: Date.now() + GENERATION.pollIntervalMs,
        });
      }
    } catch (error) {
      await this.store.update(task.jobKey, {
        nextPollAt: Date.now() + GENERATION.pollIntervalMs,
        failReason: `查询失败：${error.message}`,
      });
    }
  }

  track(map, key, promise) {
    const tracked = promise.catch((error) => console.error(`${key}: ${error.message}`))
      .finally(() => map.delete(key));
    map.set(key, tracked);
  }

  active() {
    return [...this.submits.values(), ...this.queries.values(), ...this.processes.values()];
  }

  hasWork() {
    return this.tasks.some((task) =>
      [STATUS.pending, STATUS.submitting, STATUS.querying, STATUS.generated]
        .includes(this.store.job(task.jobKey).status));
  }
}

async function downloadAndProcess(store, task, resultUrl) {
  try {
    if (!(await pathExists(task.originalPath))) {
      if (!resultUrl) throw new Error('缺少结果 URL');
      await downloadOriginal(resultUrl, task.originalPath);
    }
    await store.update(task.jobKey, { status: STATUS.processing });
    await processOriginal(task);
    await store.update(task.jobKey, { status: STATUS.success, failReason: null });
  } catch (error) {
    await store.update(task.jobKey, { status: STATUS.failed, failReason: error.message });
  }
}

function printSummary(store, tasks) {
  const counts = {};
  for (const task of tasks) {
    const status = store.job(task.jobKey).status;
    counts[status] = (counts[status] ?? 0) + 1;
  }
  console.table(counts);
}
