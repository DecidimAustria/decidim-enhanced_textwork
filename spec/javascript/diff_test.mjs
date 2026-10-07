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

const { presentationDiff, normalizeText } = await import('../../app/packs/src/decidim/textwork/diff.mjs');
const green = 'Öffentliche Grünflächen sollen gut erreichbar und für alle Menschen nutzbar sein.';
const trees = 'Wir möchten mehr Bäume und schattige Sitzplätze in unserem Viertel schaffen.';
const cases = [
  [green, green.replace('gut', 'barrierefrei')],
  [trees, trees.replace('Bäume', 'Bäume, Sonnensegel')],
  [trees, 'Wir möchten mehr Bäume und schattige Sitzplätze schaffen, insbesondere beim Spielplatz.'],
  [trees, trees.replace('in unserem Viertel ', '')],
  ['Dafür ist die Zustimmung erforderlich.', 'Dafür ist die Zustimmung erforderlich?'],
  ['- Regelmäßige Treffen im Viertel\n- Eine Ansprechperson in der Verwaltung', '- Regelmäßige Treffen im Viertel\n- Eine Ansprechperson in der Verwaltung\n- Ein Fest im Sommer'],
  [green, 'Parks und Grünflächen müssen ohne Hindernisse zugänglich sein. Niemand darf ausgeschlossen werden.'],
  ['Ein  Satz mit doppeltem Leerzeichen.', 'Ein Satz mit doppeltem Leerzeichen.'],
  ['- Erster Punkt\r\n- Zweiter Punkt', '- Erster Punkt\n- Zweiter Punkt']
];
const results = cases.map(([left, right]) => presentationDiff(left, right));
assert.equal(results[0].groups, 1);
assert.deepEqual(results[0].segments.filter(seg => seg.kind !== 'same'), [{kind:'del',text:'gut'}, {kind:'ins',text:'barrierefrei'}]);
assert.equal(results[1].groups, 1);
assert.ok(results[1].segments.some(seg => seg.kind === 'ins' && seg.text.includes(', Sonnensegel')));
assert.ok(results[2].segments.some(seg => seg.kind === 'del' && seg.text.includes('in unserem Viertel')));
assert.ok(results[2].segments.some(seg => seg.kind === 'ins' && seg.text.includes('insbesondere beim Spielplatz.')));
assert.equal(results[3].groups, 1);
assert.ok(results[3].segments.some(seg => seg.kind === 'del'));
assert.ok(!results[3].segments.some(seg => seg.kind === 'ins'));
assert.ok(results[4].changed && results[4].segments.some(seg => seg.kind === 'ins' && seg.text.includes('?')));
assert.deepEqual(results[5].segments.filter(seg => seg.kind === 'ins').map(seg => seg.text), ['- Ein Fest im Sommer']);
assert.ok(results[6].big);
assert.ok(!results[7].changed && !results[8].changed);
for (const result of results) {
  result.segments.filter(seg => seg.kind !== 'same').forEach(seg => assert.equal(seg.text, seg.text.trim()));
  result.segments.forEach((seg, index) => assert.ok(!(seg.kind === 'del' && result.segments[index - 1]?.kind === 'ins')));
}
assert.equal(normalizeText(' A  B\r\n C '), normalizeText('A B\nC'));
assert.notEqual(normalizeText('- A\n- B'), normalizeText('- A - B'));
console.log('All nine binding presentation cases pass; punctuation, groups, lists, whitespace and CRLF are covered.');
