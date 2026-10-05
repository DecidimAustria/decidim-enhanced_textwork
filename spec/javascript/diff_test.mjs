import assert from 'node:assert/strict';
import { diffTokens, diffSnippet } from '../../app/packs/src/decidim/textwork/diff.mjs';
for (const [before, after] of [['Trees.', 'Trees!'], ['- A\n- B', '- A\n- B\n- C'], ['**Bold**', '*Bold*'], ['<script>evil()</script>', 'safe'], ['a '.repeat(2000), 'b '.repeat(2000)]]) {
  const tokens = diffTokens(before, after);
  assert.equal(tokens.filter(item => item.kind !== 'ins').map(item => item.text).join(''), before);
  assert.equal(tokens.filter(item => item.kind !== 'del').map(item => item.text).join(''), after);
  assert.ok(tokens.some(item => item.kind !== 'same'));
}
console.log('Diff preserves original and replacement, including punctuation, list lines and long text.');

const before = 'One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen.';
const after = before.replace('six', 'SIX').replace('twelve', 'TWELVE');
const full = diffTokens(before, after);
const short = diffSnippet(full);
assert.deepEqual(short.filter(s => s.kind !== 'same'), full.filter(s => s.kind !== 'same'));
assert.ok(short.map(s => s.text).join('').startsWith(' … three four five '));
assert.ok(short.map(s => s.text).join('').endsWith(' thirteen fourteen fifteen.'));
assert.ok(short.map(s => s.text).join('').length < full.map(s => s.text).join('').length);
assert.deepEqual(diffSnippet(diffTokens('Add', 'Add trees')), diffTokens('Add', 'Add trees'));
console.log('Card excerpts shorten unchanged context without omitting any edits.');
