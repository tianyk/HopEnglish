import fs from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';
import { GENERATION } from './config.mjs';
import { pathExists } from './utils.mjs';

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

export async function downloadOriginal(url, destination) {
  await fs.mkdir(path.dirname(destination), { recursive: true });
  const response = await fetch(url, { redirect: 'follow', signal: AbortSignal.timeout(60_000) });
  if (!response.ok) throw new Error(`下载失败：HTTP ${response.status}`);
  const buffer = Buffer.from(await response.arrayBuffer());
  if (!buffer.subarray(0, 8).equals(PNG_SIGNATURE)) throw new Error('返回文件不是 PNG');

  const metadata = await sharp(buffer).metadata();
  if (!metadata.width || metadata.width !== metadata.height || metadata.width < 1024) {
    throw new Error(`原图尺寸异常：${metadata.width}x${metadata.height}`);
  }
  const temp = `${destination}.part`;
  await fs.writeFile(temp, buffer);
  await fs.rename(temp, destination);
}

export async function processOriginal(task) {
  const { data, info } = await sharp(task.originalPath)
    .removeAlpha()
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  const background = sampleCorners(data, info.width, info.height);
  const expected = parseHex(task.chromaKey);
  if (distance(background, expected) > 135) {
    throw new Error(`背景色与 ${task.chromaKey} 差异过大`);
  }

  const rgba = removeBackground(
    data,
    info.width,
    info.height,
    background,
    GENERATION.backgroundTolerance,
  );
  const bounds = findBounds(rgba, info.width, info.height);
  if (!bounds) throw new Error('去背景后没有主体');
  if (bounds.minX === 0 || bounds.minY === 0 || bounds.maxX === info.width - 1 || bounds.maxY === info.height - 1) {
    throw new Error('主体接触画布边缘');
  }

  const cropWidth = bounds.maxX - bounds.minX + 1;
  const cropHeight = bounds.maxY - bounds.minY + 1;
  const maxSize = Math.round(GENERATION.outputSize * GENERATION.subjectMaxRatio);
  const scale = Math.min(maxSize / cropWidth, maxSize / cropHeight);
  const width = Math.max(1, Math.round(cropWidth * scale));
  const height = Math.max(1, Math.round(cropHeight * scale));
  const subject = await sharp(rgba, {
    raw: { width: info.width, height: info.height, channels: 4 },
  })
    .extract({ left: bounds.minX, top: bounds.minY, width: cropWidth, height: cropHeight })
    .resize(width, height)
    .png()
    .toBuffer();

  await fs.mkdir(path.dirname(task.outputPath), { recursive: true });
  const temp = `${task.outputPath}.part`;
  const { data: composed, info: composedInfo } = await sharp({
    create: {
      width: GENERATION.outputSize,
      height: GENERATION.outputSize,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite([{
      input: subject,
      left: Math.round((GENERATION.outputSize - width) / 2),
      top: Math.round((GENERATION.outputSize - height) / 2),
    }])
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  // 缩放和合成会把透明像素中残留的色键 RGB 混入最外侧抗锯齿像素，
  // 因此在最终尺寸上再清理一次边缘溢色。
  removeChromaFringe(composed, composedInfo.width, composedInfo.height, background);
  neutralizeTransparentPixels(composed);
  await sharp(composed, {
    raw: {
      width: composedInfo.width,
      height: composedInfo.height,
      channels: composedInfo.channels,
    },
  })
    .png({ compressionLevel: 9 })
    .toFile(temp);
  await fs.rename(temp, task.outputPath);

  const valid = await validateFinalImage(task.outputPath);
  if (!valid.ok) throw new Error(valid.error);
}

export async function validateFinalImage(filePath) {
  if (!(await pathExists(filePath))) return { ok: false, error: '文件不存在' };
  try {
    const image = sharp(filePath);
    const metadata = await image.metadata();
    if (metadata.width !== 512 || metadata.height !== 512 || !metadata.hasAlpha) {
      return { ok: false, error: '成品必须是 512x512 RGBA PNG' };
    }
    const { data, info } = await image.ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const cornerOffsets = [
      3,
      (info.width - 1) * 4 + 3,
      ((info.height - 1) * info.width) * 4 + 3,
      (info.height * info.width - 1) * 4 + 3,
    ];
    if (cornerOffsets.some((offset) => data[offset] !== 0)) {
      return { ok: false, error: '成品四角必须透明' };
    }
    return { ok: true };
  } catch (error) {
    return { ok: false, error: error.message };
  }
}

export async function cleanFinalImageFringe(filePath, chromaKey) {
  const key = typeof chromaKey === 'string' ? parseHex(chromaKey) : chromaKey;
  const { data, info } = await sharp(filePath).ensureAlpha().raw()
    .toBuffer({ resolveWithObject: true });
  removeChromaFringe(data, info.width, info.height, key);
  neutralizeTransparentPixels(data);
  const temp = `${filePath}.fringe-cleanup`;
  await sharp(data, {
    raw: { width: info.width, height: info.height, channels: info.channels },
  })
    .png({ compressionLevel: 9 })
    .toFile(temp);
  await fs.rename(temp, filePath);
}

export function removeBackground(data, width, height, background, tolerance) {
  const pixels = width * height;
  const removed = new Uint8Array(pixels);
  const queue = new Int32Array(pixels);
  const seedTolerance = Math.min(tolerance, 36);
  let head = 0;
  let tail = 0;
  const enqueue = (index, maximumDistance = tolerance) => {
    if (removed[index]) return;
    const offset = index * 4;
    if (distance(
      [data[offset], data[offset + 1], data[offset + 2]],
      background,
    ) > maximumDistance) return;
    removed[index] = 1;
    queue[tail++] = index;
  };

  for (let x = 0; x < width; x += 1) {
    enqueue(x, seedTolerance);
    enqueue((height - 1) * width + x, seedTolerance);
  }
  for (let y = 0; y < height; y += 1) {
    enqueue(y * width, seedTolerance);
    enqueue(y * width + width - 1, seedTolerance);
  }
  while (head < tail) {
    const index = queue[head++];
    const x = index % width;
    const y = Math.floor(index / width);
    if (x > 0) enqueue(index - 1);
    if (x + 1 < width) enqueue(index + 1);
    if (y > 0) enqueue(index - width);
    if (y + 1 < height) enqueue(index + width);
  }

  const output = Buffer.from(data);
  for (let index = 0; index < pixels; index += 1) {
    if (removed[index]) output[index * 4 + 3] = 0;
  }
  // 色键区域可能被四肢、把手、果梗等主体结构完全包围，无法从画布边缘
  // flood-fill 到。只清除面积足够大的封闭色键连通块，避免误伤果梗等主体
  // 中少量接近色键的自然颜色。
  removeEnclosedChromaComponents(
    output,
    width,
    height,
    background,
    seedTolerance,
    tolerance,
  );
  removeChromaFringe(output, width, height, background);
  return output;
}

function removeEnclosedChromaComponents(
  data,
  width,
  height,
  background,
  seedTolerance,
  expansionTolerance,
) {
  const pixels = width * height;
  const checked = new Uint8Array(pixels);
  const queue = new Int32Array(pixels);
  const minimumArea = Math.max(1, Math.round(pixels / 20_000));
  const colorDistance = (index) => {
    const offset = index * 4;
    if (data[offset + 3] < 20) return Number.POSITIVE_INFINITY;
    return distance([data[offset], data[offset + 1], data[offset + 2]], background);
  };
  const isSeed = (index) => colorDistance(index) <= seedTolerance;
  const isChroma = (index) => colorDistance(index) <= expansionTolerance;

  for (let start = 0; start < pixels; start += 1) {
    if (checked[start] || !isSeed(start)) continue;
    let head = 0;
    let tail = 0;
    checked[start] = 1;
    queue[tail++] = start;
    while (head < tail) {
      const index = queue[head++];
      const x = index % width;
      const y = Math.floor(index / width);
      const neighbors = [];
      if (x > 0) neighbors.push(index - 1);
      if (x + 1 < width) neighbors.push(index + 1);
      if (y > 0) neighbors.push(index - width);
      if (y + 1 < height) neighbors.push(index + width);
      for (const neighbor of neighbors) {
        if (checked[neighbor] || !isChroma(neighbor)) continue;
        checked[neighbor] = 1;
        queue[tail++] = neighbor;
      }
    }
    if (tail < minimumArea) continue;
    for (let index = 0; index < tail; index += 1) {
      data[queue[index] * 4 + 3] = 0;
    }
  }
}

function removeChromaFringe(data, width, height, background) {
  const pixels = width * height;
  const toRemove = new Uint8Array(pixels);
  const removedAlpha = new Uint8Array(pixels);
  const fringeTolerance = 180;
  for (let pass = 0; pass < 6; pass += 1) {
    toRemove.fill(0);
    let count = 0;
    for (let y = 1; y < height - 1; y += 1) {
      for (let x = 1; x < width - 1; x += 1) {
        const index = y * width + x;
        const offset = index * 4;
        if (data[offset + 3] === 0) continue;
        const colorDistance = distance(
          [data[offset], data[offset + 1], data[offset + 2]],
          background,
        );
        const dominance = chromaDominance(
          data[offset],
          data[offset + 1],
          data[offset + 2],
          background,
        );
        if (colorDistance > fringeTolerance && dominance < 12) continue;
        const neighbors = [
          index - width - 1, index - width, index - width + 1,
          index - 1, index + 1,
          index + width - 1, index + width, index + width + 1,
        ];
        if (!neighbors.some((neighbor) => data[neighbor * 4 + 3] === 0)) continue;
        toRemove[index] = 1;
        count += 1;
      }
    }
    if (count === 0) break;
    for (let index = 0; index < pixels; index += 1) {
      if (!toRemove[index]) continue;
      const offset = index * 4;
      if (removedAlpha[index] === 0) removedAlpha[index] = data[offset + 3];
      data[offset + 3] = 0;
    }
  }
  for (let index = 0; index < pixels; index += 1) {
    if (removedAlpha[index] === 0) continue;
    const offset = index * 4;
    data[offset] = 255;
    data[offset + 1] = 255;
    data[offset + 2] = 255;
    data[offset + 3] = removedAlpha[index];
  }
}

function chromaDominance(r, g, b, key) {
  if (key[0] > 200 && key[2] > 200) return Math.min(r, b) - g;
  if (key[1] > key[0] && key[1] > key[2]) return g - Math.max(r, b);
  if (key[2] > key[0] && key[2] > key[1]) return b - Math.max(r, g);
  return 0;
}

function neutralizeTransparentPixels(data) {
  for (let offset = 0; offset < data.length; offset += 4) {
    if (data[offset + 3] !== 0) continue;
    data[offset] = 255;
    data[offset + 1] = 255;
    data[offset + 2] = 255;
  }
}

function sampleCorners(data, width, height) {
  const points = [[0, 0], [width - 1, 0], [0, height - 1], [width - 1, height - 1]];
  return [0, 1, 2].map((channel) => Math.round(points.reduce((sum, [x, y]) =>
    sum + data[(y * width + x) * 4 + channel], 0) / points.length));
}

function findBounds(data, width, height) {
  let minX = width;
  let minY = height;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      if (data[(y * width + x) * 4 + 3] < 20) continue;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  return maxX < 0 ? null : { minX, minY, maxX, maxY };
}

function parseHex(hex) {
  return [1, 3, 5].map((start) => Number.parseInt(hex.slice(start, start + 2), 16));
}

function distance(a, b) {
  return Math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2);
}
