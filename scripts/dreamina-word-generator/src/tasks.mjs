import path from 'node:path';
import { buildCategoryIconPrompt, buildPrompt, chooseChromaKey } from './prompt-templates.mjs';
import { PATHS } from './config.mjs';
import { readJson } from './utils.mjs';

export async function buildTaskManifest() {
  const [categories, overrides] = await Promise.all([
    readJson(PATHS.categories),
    readJson(PATHS.overrides),
  ]);
  validateCategories(categories);

  const tasks = [];
  const jobKeys = new Set();
  const filenames = new Set();

  for (const category of categories) {
    for (const word of category.words) {
      const jobKey = `${category.id}/${word.id}`;
      const filename = `${safeName(category.id)}_${safeName(word.id)}.png`;
      if (jobKeys.has(jobKey)) throw new Error(`重复任务键：${jobKey}`);
      if (filenames.has(filename)) throw new Error(`重复输出文件名：${filename}`);

      const task = {
        jobKey,
        categoryId: category.id,
        categoryName: category.name,
        wordId: word.id,
        name: word.name,
        nameZh: word.nameZh ?? '',
        filename,
        outputPath: path.join(PATHS.words, filename),
        originalPath: path.join(PATHS.originals, filename),
      };
      const override = overrides[jobKey] ?? {};
      task.chromaKey = override.chromaKey ?? chooseChromaKey(task);
      task.prompt = buildPrompt(task, override);

      jobKeys.add(jobKey);
      filenames.add(filename);
      tasks.push(task);
    }
  }

  return { categories, tasks };
}

export async function buildCategoryIconManifest() {
  const [categories, overrides] = await Promise.all([
    readJson(PATHS.categories),
    readJson(PATHS.categoryOverrides),
  ]);
  validateCategories(categories);
  const tasks = categories.map((category) => {
    const override = overrides[category.id];
    if (!override?.subject) throw new Error(`分类 ${category.id} 缺少图标提示词`);
    const filename = `${safeName(category.id)}.png`;
    const task = {
      jobKey: `category-icon/${category.id}`,
      categoryId: category.id,
      categoryName: category.name,
      wordId: category.id,
      name: category.name,
      nameZh: '',
      filename,
      outputPath: path.join(PATHS.categoryImages, filename),
      originalPath: path.join(PATHS.categoryOriginals, filename),
      candidatePath: path.join(PATHS.categoryCandidates, filename),
      candidateOriginalPath: path.join(PATHS.categoryCandidateOriginals, filename),
    };
    task.chromaKey = override.chromaKey ?? '#FF00FF';
    task.prompt = buildCategoryIconPrompt(task, override);
    return task;
  });
  return { categories, tasks };
}

export function selectTasks(tasks, options) {
  let selected = tasks;
  if (options.category) selected = selected.filter((task) => task.categoryId === options.category);
  if (options.words?.length) {
    const words = new Set(options.words);
    selected = selected.filter((task) =>
      words.has(task.wordId) || words.has(task.jobKey));
  }
  if (options.limit) selected = selected.slice(0, options.limit);
  if ((options.category || options.words?.length) && selected.length === 0) {
    throw new Error('筛选条件没有匹配任何单词');
  }
  if (options.words?.length) {
    const matched = new Set(selected.flatMap((task) => [task.wordId, task.jobKey]));
    const missing = options.words.filter((word) => !matched.has(word));
    if (missing.length > 0) throw new Error(`没有匹配到这些单词：${missing.join(', ')}`);
  }
  return selected;
}

export function selectCategoryIconTasks(tasks, options) {
  let selected = tasks;
  if (options.category) {
    selected = selected.filter((task) => task.categoryId === options.category);
  }
  if (options.limit) selected = selected.slice(0, options.limit);
  if (options.category && selected.length === 0) {
    throw new Error(`没有匹配到分类：${options.category}`);
  }
  return selected;
}

export function applyImagesToCategories(categories, tasks, successfulJobKeys, allowPartial = false) {
  const byKey = new Map(tasks.map((task) => [task.jobKey, task]));
  const missing = tasks.filter((task) => !successfulJobKeys.has(task.jobKey));
  if (missing.length > 0 && !allowPartial) {
    throw new Error(`仍有 ${missing.length} 个任务未成功；使用 --allow-partial 可只应用成功项`);
  }

  return categories.map((category) => ({
    ...category,
    words: category.words.map((word) => {
      const jobKey = `${category.id}/${word.id}`;
      const task = byKey.get(jobKey);
      if (!task || !successfulJobKeys.has(jobKey)) return word;
      return { ...word, image: task.filename };
    }),
  }));
}

export function applyCategoryImages(categories, tasks, successfulJobKeys) {
  const byCategory = new Map(tasks.map((task) => [task.categoryId, task]));
  return categories.map((category) => {
    const task = byCategory.get(category.id);
    if (!task || !successfulJobKeys.has(task.jobKey)) return category;
    return { ...category, image: task.filename };
  });
}

function validateCategories(categories) {
  if (!Array.isArray(categories) || categories.length === 0) {
    throw new Error('categories.json 必须是非空数组');
  }
  for (const category of categories) {
    if (!category.id || !category.name || !Array.isArray(category.words)) {
      throw new Error('分类缺少 id、name 或 words');
    }
    for (const word of category.words) {
      if (!word.id || !word.name || !word.audio) {
        throw new Error(`${category.id} 中存在缺少 id、name 或 audio 的单词`);
      }
    }
  }
}

function safeName(value) {
  const safe = String(value).toLowerCase().replace(/[^a-z0-9_]+/g, '_').replace(/^_+|_+$/g, '');
  if (!safe) throw new Error(`无法生成安全文件名：${value}`);
  return safe;
}
