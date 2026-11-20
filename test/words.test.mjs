import { test } from "node:test";
import assert from "node:assert/strict";
import { extractWordsNewestFirst, filterWords } from "../mod/words.js";

test("lists words newest first, once each, skipping short words", () => {
  assert.deepEqual(extractWordsNewestFirst("alpha beta ab\ngamma alpha"), ["alpha", "gamma", "beta"]);
});

test("trims surrounding quotes, brackets and trailing punctuation", () => {
  assert.deepEqual(
    extractWordsNewestFirst('"quoted" (paren) <angle> path/to/file.java:42: end.'),
    ["end", "path/to/file.java:42", "angle", "paren", "quoted"],
  );
});

test("counts characters, not bytes, toward the minimum length", () => {
  assert.deepEqual(extractWordsNewestFirst("éé ééé"), ["ééé"]);
});

test("an empty query keeps every word in order", () => {
  assert.deepEqual(filterWords(["b", "a"], ""), ["b", "a"]);
});

test("prefix matches come before substring and scattered matches, newest first within each", () => {
  const words = ["xrouter", "r-o-u-t", "routes", "PaymentRouter", "router"];
  assert.deepEqual(filterWords(words, "rout"), ["routes", "router", "xrouter", "PaymentRouter", "r-o-u-t"]);
});

test("a lowercase query ignores case, an uppercase one does not", () => {
  const words = ["PaymentRouter", "paymentrouter"];
  assert.deepEqual(filterWords(words, "router"), ["PaymentRouter", "paymentrouter"]);
  assert.deepEqual(filterWords(words, "Router"), ["PaymentRouter"]);
});

test("drops words missing a query character", () => {
  assert.deepEqual(filterWords(["alpha", "beta"], "z"), []);
});
