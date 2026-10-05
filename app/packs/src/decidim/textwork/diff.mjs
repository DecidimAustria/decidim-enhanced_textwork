// LCS uses conventional matrix indices; increments advance exactly one token.
/* eslint id-length: ["error", {"exceptions": ["a", "b", "i", "j"]}], no-plusplus: "off" */
// Whitespace, newlines and punctuation are tokens too: none may disappear.
export const diffTokens = (original, replacement) => {
  const tokenize = (text) =>
    String(text).match(/\s+|[\p{L}\p{N}_]+|[^\s]/gu) || [];
  const left = tokenize(original),
      right = tokenize(replacement);
  let prefix = 0,
      suffix = 0;
  while (
    prefix < left.length &&
    prefix < right.length &&
    left[prefix] === right[prefix]
  ) {
    prefix++;
  }
  while (
    suffix < left.length - prefix &&
    suffix < right.length - prefix &&
    left[left.length - 1 - suffix] === right[right.length - 1 - suffix]
  ) {
    suffix++;
  }
  const a = left.slice(prefix, left.length - suffix),
      b = right.slice(prefix, right.length - suffix);
  const result = [];
  const push = (kind, text) => {
    if (!text) {
      return;
    }
    if (result.at(-1)?.kind === kind) {
      result.at(-1).text += text;
    } else {
      result.push({ kind, text });
    }
  };
  push("same", left.slice(0, prefix).join(""));
  // Bound typing latency for entirely different long paragraphs.
  if (a.length * b.length > 1000000) {
    push("del", a.join(""));
    push("ins", b.join(""));
  } else {
    const table = Array.from(
      { length: a.length + 1 },
      () => new Uint16Array(b.length + 1)
    );
    for (let i = a.length - 1; i >= 0; i--) {
      for (let j = b.length - 1; j >= 0; j--) {
        table[i][j] =
          a[i] === b[j]
            ? table[i + 1][j + 1] + 1
            : Math.max(table[i + 1][j], table[i][j + 1]);
      }
    }
    let i = 0,
        j = 0;
    while (i < a.length && j < b.length) {
      if (a[i] === b[j]) {
        push("same", a[i++]);
        j++;
      } else if (table[i + 1][j] >= table[i][j + 1]) {
        push("del", a[i++]);
      } else {
        push("ins", b[j++]);
      }
    }
    while (i < a.length) {
      push("del", a[i++]);
    }
    while (j < b.length) {
      push("ins", b[j++]);
    }
  }
  push("same", suffix
    ? left.slice(-suffix).join("")
    : "");
  return result;
};

// Preserve every change, shortening only unchanged context between/around edits.
export const diffSnippet = (segments, context = 3) => segments.flatMap((segment, index) => {
  if (segment.kind !== "same") {
    return [segment];
  }
  const words = [...segment.text.matchAll(/\S+/gu)];
  const before = index > 0;
  const after = index < segments.length - 1;
  const keep = (before
    ? context
    : 0) + (after
    ? context
    : 0);
  if (words.length <= keep || (!before && !after)) {
    return [segment];
  }
  const head = before
    ? segment.text.slice(0, words[context - 1].index + words[context - 1][0].length)
    : "";
  const tail = after
    ? segment.text.slice(words[words.length - context].index)
    : "";
  return [{ kind: "same", text: `${head} … ${tail}` }];
});

// The fourth argument selects a presentation, keeping the comparison identical.
// eslint-disable-next-line max-params
export const renderDiff = (container, original, replacement, compact = false) => {
  const segments = diffTokens(original, replacement);
  container.replaceChildren(
    ...(compact
      ? diffSnippet(segments)
      : segments).map(({ kind, text }) => {
      if (kind === "same") {
        return document.createTextNode(text);
      }
      const element = document.createElement(kind);
      element.textContent = text;
      return element;
    })
  );
};
