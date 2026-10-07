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
      result.push({
        kind,
        text
      });
    }
  };
  push("same", left.slice(0, prefix).join(""));
  // Bound typing latency for entirely different long paragraphs.
  if (a.length * b.length > 1000000) {
    push("del", a.join(""));
    push("ins", b.join(""));
  } else {
    const table = Array.from(
      {
        length: a.length + 1
      },
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
export const diffSnippet = (segments, context = 3) =>
  segments.flatMap((segment, index) => {
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
      ? segment.text.slice(
        0,
        words[context - 1].index + words[context - 1][0].length
      )
      : "";
    const tail = after
      ? segment.text.slice(words[words.length - context].index)
      : "";
    return [
      {
        kind: "same",
        text: `${head} … ${tail}`
      }
    ];
  });
export const normalizeText = (text) =>
  String(text).
    replace(/\r\n?/gu, "\n").
    split("\n").
    map((line) => line.trim().replace(/[ \t]+/gu, " ")).
    join("\n").
    trim();
const wordCount = (text) =>
  (String(text).match(/[\p{L}\p{N}_]+/gu) || []).length;
const movesPeriod = (token, insertion) =>
  token?.kind === "same" &&
  (/^[.!?]$/u).test(token.text) &&
  (/[,;:]/u).test(insertion) &&
  wordCount(insertion) > 0;
// Presentation groups only. The lossless, bounded token comparison above is kept.
export const presentationDiff = (original, replacement) => {
  const before = String(original).replace(/\r\n?/gu, "\n");
  const after = String(replacement).replace(/\r\n?/gu, "\n");
  if (normalizeText(before) === normalizeText(after)) {
    return {
      segments: [
        {
          kind: "same",
          text: after
        }
      ],
      changed: false,
      big: false,
      groups: 0
    };
  }
  const raw = diffTokens(before, after);
  const segments = [];
  let groups = 0;
  let deleted = 0;
  let inserted = 0;
  const append = (kind, text) => {
    if (!text) {
      return;
    }
    if (segments.at(-1)?.kind === kind) {
      segments.at(-1).text += text;
    } else {
      segments.push({
        kind,
        text
      });
    }
  };
  for (let index = 0; index < raw.length; index++) {
    if (raw[index].kind === "same") {
      append("same", raw[index].text);
    } else {
      const parts = {
        del: "",
        ins: ""
      };
      while (index < raw.length) {
        const token = raw[index];
        if (token.kind !== "same") {
          parts[token.kind] += token.text;
        } else if (
          (/^\s+$/u).test(token.text) &&
          raw[index + 1]?.kind !== "same" &&
          raw[index + 1]
        ) {
          parts.del += token.text;
          parts.ins += token.text;
        } else {
          break;
        }
        index++;
      }
      // A sentence-final period moves when a new clause replaces the sentence end.
      if (movesPeriod(raw[index], parts.ins)) {
        parts.del += raw[index].text;
        parts.ins += raw[index].text;
        index++;
      }
      index--;
      const leading =
        parts.del.match(/^\s+/u)?.[0] || parts.ins.match(/^\s+/u)?.[0] || "";
      const trailing =
        parts.del.match(/\s+$/u)?.[0] || parts.ins.match(/\s+$/u)?.[0] || "";
      append("same", leading);
      const removed = parts.del.trim();
      const added = parts.ins.trim();
      if (removed || added) {
        groups++;
      }
      deleted += wordCount(removed);
      inserted += wordCount(added);
      append("del", removed);
      append("ins", added);
      append("same", trailing);
    }
  }
  const affected = Math.max(deleted, inserted);
  return {
    segments,
    changed: true,
    groups,
    big:
      groups > 3 ||
      (affected > 5 && affected > wordCount(before) / 2) ||
      groups === 0
  };
};
/* eslint-disable max-params */
export const renderDiff = (
  container,
  original,
  replacement,
  compact = false,
  labels = {}
) => {
  const result = presentationDiff(original, replacement);
  if (container.hasAttribute("data-live-diff")) {
    container.classList.toggle("tw-preview-empty", !result.changed);
  }
  if (!result.changed && container.hasAttribute("data-live-diff")) {
    container.textContent = labels.previewEmpty || "";
    return;
  }
  if (result.big) {
    container.replaceChildren(
      ...[
        ["tw-before", labels.before, original],
        ["tw-after", labels.after, replacement]
      ].map(([className, label, text]) => {
        const section = document.createElement("div");
        section.className = className;
        const heading = document.createElement("strong");
        heading.textContent = label;
        const body = document.createElement("div");
        body.textContent = text;
        section.append(heading, body);
        return section;
      })
    );
    return;
  }
  const segments =
    compact && wordCount(original) > 40
      ? diffSnippet(result.segments)
      : result.segments;
  container.replaceChildren(
    ...segments.map(({ kind, text }) => {
      if (kind === "same") {
        return document.createTextNode(text);
      }
      const element = document.createElement(kind);
      element.textContent = text;
      return element;
    })
  );
};

/* eslint-enable max-params */
