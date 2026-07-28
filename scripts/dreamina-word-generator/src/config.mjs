import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const TOOL_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const REPO_ROOT = path.resolve(TOOL_DIR, '../..');

export const PATHS = Object.freeze({
  categories: path.join(REPO_ROOT, 'assets/data/categories.json'),
  words: path.join(REPO_ROOT, 'assets/images/words'),
  overrides: path.join(TOOL_DIR, 'prompt-overrides.json'),
  stateDir: path.join(TOOL_DIR, '.state'),
  state: path.join(TOOL_DIR, '.state/state.json'),
  originals: path.join(TOOL_DIR, '.state/originals'),
  candidates: path.join(TOOL_DIR, '.state/candidates'),
  candidateOriginals: path.join(TOOL_DIR, '.state/candidate-originals'),
  promptPreview: path.join(TOOL_DIR, '.state/prompts.json'),
});

export const GENERATION = Object.freeze({
  modelVersion: '5.0',
  resolution: '2k',
  ratio: '1:1',
  creditsPerImage: 3,
  submitConcurrency: 3,
  queryConcurrency: 4,
  cliConcurrency: 4,
  processingConcurrency: 2,
  maxRemoteInFlight: 12,
  firstPollDelayMs: 20_000,
  pollIntervalMs: 10_000,
  outputSize: 512,
  subjectMaxRatio: 0.78,
  backgroundTolerance: 72,
});

export const STATUS = Object.freeze({
  pending: 'pending',
  submitting: 'submitting',
  querying: 'querying',
  generated: 'generated',
  processing: 'processing',
  success: 'success',
  failed: 'failed',
  submittingUnknown: 'submitting_unknown',
});
