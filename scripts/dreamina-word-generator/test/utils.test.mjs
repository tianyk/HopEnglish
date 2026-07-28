import assert from 'node:assert/strict';
import test from 'node:test';
import { parseArgs } from '../src/utils.mjs';

test('parses and deduplicates multiple word selectors', () => {
  const options = parseArgs([
    '--word=nature/moon',
    '--words=actions/swim,nature/moon',
    '--candidate',
    '--force',
  ]);
  assert.deepEqual(options.words, ['nature/moon', 'actions/swim']);
  assert.equal(options.candidate, true);
  assert.equal(options.force, true);
});
