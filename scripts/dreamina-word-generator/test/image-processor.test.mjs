import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import sharp from 'sharp';
import { cleanFinalImageFringe, removeBackground } from '../src/image-processor.mjs';

test('removes chroma-key pixels enclosed by the subject', () => {
  const width = 5;
  const height = 5;
  const magenta = [255, 0, 255, 255];
  const subject = [120, 80, 40, 255];
  const pixels = Buffer.alloc(width * height * 4);

  for (let index = 0; index < width * height; index += 1) {
    pixels.set(magenta, index * 4);
  }
  for (let y = 1; y <= 3; y += 1) {
    for (let x = 1; x <= 3; x += 1) {
      pixels.set(subject, (y * width + x) * 4);
    }
  }
  pixels.set(magenta, (2 * width + 2) * 4);

  const output = removeBackground(pixels, width, height, magenta.slice(0, 3), 72);
  assert.equal(output[(2 * width + 2) * 4 + 3], 0);
  assert.equal(output[(1 * width + 1) * 4 + 3], 255);
});

test('preserves a natural green subject when removing neon green', () => {
  const width = 200;
  const height = 200;
  const neonGreen = [0, 255, 0, 255];
  const subject = [120, 80, 40, 255];
  const naturalGreen = [38, 225, 48, 255];
  const pixels = Buffer.alloc(width * height * 4);

  for (let index = 0; index < width * height; index += 1) {
    pixels.set(neonGreen, index * 4);
  }
  for (let y = 50; y < 150; y += 1) {
    for (let x = 50; x < 150; x += 1) {
      pixels.set(subject, (y * width + x) * 4);
    }
  }
  pixels.set(naturalGreen, (100 * width + 100) * 4);

  const output = removeBackground(pixels, width, height, [0, 255, 0], 72);
  assert.equal(output[3], 0);
  assert.equal(output[(100 * width + 100) * 4 + 3], 255);
});

test('removes enclosed key-colored fringe next to transparent background', () => {
  const width = 7;
  const height = 7;
  const magenta = [255, 0, 255, 255];
  const fringe = [240, 45, 210, 255];
  const white = [255, 255, 255, 255];
  const pixels = Buffer.alloc(width * height * 4);
  for (let index = 0; index < width * height; index += 1) {
    pixels.set(magenta, index * 4);
  }
  for (let y = 2; y <= 4; y += 1) {
    for (let x = 2; x <= 4; x += 1) {
      pixels.set(fringe, (y * width + x) * 4);
    }
  }
  pixels.set(white, (3 * width + 3) * 4);

  const output = removeBackground(pixels, width, height, magenta.slice(0, 3), 72);
  assert.equal(output[(2 * width + 2) * 4 + 3], 0);
  assert.equal(output[(3 * width + 3) * 4 + 3], 255);
});

test('removes pale chroma spill but stops at the white sticker border', () => {
  const width = 9;
  const height = 9;
  const transparent = [0, 0, 0, 0];
  const paleMagenta = [255, 210, 250, 255];
  const white = [255, 255, 255, 255];
  const subject = [80, 120, 200, 255];
  const pixels = Buffer.alloc(width * height * 4);
  for (let index = 0; index < width * height; index += 1) {
    pixels.set(transparent, index * 4);
  }
  for (let y = 2; y <= 6; y += 1) {
    for (let x = 2; x <= 6; x += 1) {
      pixels.set(paleMagenta, (y * width + x) * 4);
    }
  }
  for (let y = 3; y <= 5; y += 1) {
    for (let x = 3; x <= 5; x += 1) {
      pixels.set(white, (y * width + x) * 4);
    }
  }
  pixels.set(subject, (4 * width + 4) * 4);

  const output = removeBackground(pixels, width, height, [255, 0, 255], 72);
  assert.deepEqual(
    [...output.subarray((2 * width + 2) * 4, (2 * width + 2) * 4 + 4)],
    [255, 255, 255, 255],
  );
  assert.equal(output[(3 * width + 3) * 4 + 3], 255);
  assert.equal(output[(4 * width + 4) * 4 + 3], 255);
});

test('neutralizes RGB values of transparent pixels in final PNG files', async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'hopenglish-fringe-'));
  const filePath = path.join(directory, 'sample.png');
  const pixels = Buffer.from([
    255, 0, 255, 0,
    255, 255, 255, 255,
  ]);
  await sharp(pixels, { raw: { width: 2, height: 1, channels: 4 } }).png().toFile(filePath);
  await cleanFinalImageFringe(filePath, '#FF00FF');
  const data = await sharp(filePath).ensureAlpha().raw().toBuffer();
  assert.deepEqual([...data.subarray(0, 4)], [255, 255, 255, 0]);
  await fs.rm(directory, { recursive: true, force: true });
});
