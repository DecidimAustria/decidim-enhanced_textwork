import assert from 'node:assert/strict';
import { diffTokens } from '../../app/packs/src/decidim/textwork/diff.mjs';
for (const [before, after] of [['Trees.', 'Trees!'], ['- A\n- B', '- A\n- B\n- C'], ['**Bold**', '*Bold*'], ['<script>evil()</script>', 'safe'], ['a '.repeat(2000), 'b '.repeat(2000)]]) {
  const tokens = diffTokens(before, after);
  assert.equal(tokens.filter(item => item.kind !== 'ins').map(item => item.text).join(''), before);
  assert.equal(tokens.filter(item => item.kind !== 'del').map(item => item.text).join(''), after);
  assert.ok(tokens.some(item => item.kind !== 'same'));
}
console.log('Diff preserves original and replacement, including punctuation, list lines and long text.');
