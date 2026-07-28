import fs from 'node:fs/promises';
import { PATHS, STATUS } from './config.mjs';
import { pathExists, readJson, writeJsonAtomic } from './utils.mjs';

export class StateStore {
  #writeQueue = Promise.resolve();

  constructor(state) {
    this.state = state;
  }

  static async open(tasks) {
    await fs.mkdir(PATHS.stateDir, { recursive: true });
    const state = await pathExists(PATHS.state)
      ? await readJson(PATHS.state)
      : { version: 1, jobs: {} };
    const store = new StateStore(state);

    for (const task of tasks) {
      const job = state.jobs[task.jobKey];
      if (!job) {
        state.jobs[task.jobKey] = createJob(task);
      } else if ([STATUS.pending, STATUS.failed].includes(job.status)) {
        job.filename = task.filename;
        job.prompt = task.prompt;
        job.chromaKey = task.chromaKey;
      }
    }
    await store.save();
    return store;
  }

  job(jobKey) {
    const job = this.state.jobs[jobKey];
    if (!job) throw new Error(`不存在任务：${jobKey}`);
    return job;
  }

  async update(jobKey, patch) {
    Object.assign(this.job(jobKey), patch, { updatedAt: new Date().toISOString() });
    await this.save();
  }

  save() {
    this.state.updatedAt = new Date().toISOString();
    this.#writeQueue = this.#writeQueue.then(() => writeJsonAtomic(PATHS.state, this.state));
    return this.#writeQueue;
  }

  flush() {
    return this.#writeQueue;
  }
}

export function canSubmit(job) {
  return job.status === STATUS.pending && !job.submitId;
}

function createJob(task) {
  return {
    jobKey: task.jobKey,
    filename: task.filename,
    prompt: task.prompt,
    chromaKey: task.chromaKey,
    status: STATUS.pending,
    submitId: null,
    resultUrl: null,
    creditCount: 0,
    failReason: null,
    nextPollAt: null,
    submittedAt: null,
    updatedAt: new Date().toISOString(),
  };
}
