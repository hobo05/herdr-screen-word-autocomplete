const LEADING_JUNK = "\"'`([{<";
const TRAILING_JUNK = "\"'`)]}>,;:.!?";
const MIN_WORD_LENGTH = 3;

export function extractWordsNewestFirst(text) {
  const lines = text.split("\n");
  const seen = new Set();
  const words = [];
  for (let i = lines.length - 1; i >= 0; i--) {
    const parts = lines[i].split(/[ \t\r]+/);
    for (let j = parts.length - 1; j >= 0; j--) {
      const word = trimJunk(parts[j]);
      if ([...word].length >= MIN_WORD_LENGTH && !seen.has(word)) {
        seen.add(word);
        words.push(word);
      }
    }
  }
  return words;
}

function trimJunk(part) {
  let start = 0;
  let end = part.length;
  while (start < end && LEADING_JUNK.includes(part[start])) start++;
  while (end > start && TRAILING_JUNK.includes(part[end - 1])) end--;
  return part.slice(start, end);
}

function containsInOrder(word, query) {
  let matched = 0;
  for (const ch of word) {
    if (ch === query[matched]) matched++;
    if (matched === query.length) return true;
  }
  return false;
}

const PREFIX = 0;
const SUBSTRING = 1;
const SCATTERED = 2;

function matchRank(word, query) {
  if (word.startsWith(query)) return PREFIX;
  if (word.includes(query)) return SUBSTRING;
  if (containsInOrder(word, query)) return SCATTERED;
  return null;
}

export function filterWords(words, query) {
  if (!query) return words;
  const caseSensitive = query !== query.toLowerCase();
  const fold = (s) => (caseSensitive ? s : s.toLowerCase());
  const needle = fold(query);
  const ranked = [];
  words.forEach((word, recency) => {
    const rank = matchRank(fold(word), needle);
    if (rank !== null) ranked.push({ rank, recency, word });
  });
  ranked.sort((a, b) => a.rank - b.rank || a.recency - b.recency);
  return ranked.map((r) => r.word);
}
