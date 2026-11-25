import { test } from "node:test";
import assert from "node:assert/strict";
import { terminalOnScreen } from "../mod/focus.js";

test("reads the pane's own terminal when nothing replaces it", () => {
  assert.equal(terminalOnScreen({ terminal: "t2c", shown: null }), "t2c");
});

test("reads the terminal a pane shows in place of its own", () => {
  assert.equal(terminalOnScreen({ terminal: "t2c", shown: "t2f" }), "t2f");
});

test("reads nothing when a mod pane has focus", () => {
  assert.equal(terminalOnScreen({ terminal: null, shown: null }), null);
});

test("reads nothing when nothing has focus", () => {
  assert.equal(terminalOnScreen(null), null);
});
