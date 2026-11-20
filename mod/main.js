import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, ScrollHandle } from "gpui-base";
import { hc, run, focused, props, closeOverlay, notify, theme, settings } from "herdr";
import { extractWordsNewestFirst, filterWords } from "./words.js";
import { clipboardTextOrNull, copiedToClipboard } from "./clipboard.js";

const SCROLLBACK_LINES = 1000;
const MAX_ROWS_SHOWN = 300;
const ROW_HEIGHT = 28;
const VISIBLE_ROWS = 12;
const COPY_SETTLE_MS = 150;
const PASTE_SETTLE_MS = 300;

export default class ScreenWord extends View {
  init(_props, cx) {
    this.terminal = focused()?.terminal ?? null;
    this.words = [];
    this.query = "";
    this.at = 0;
    this.withScrollback = false;
    this.loading = true;
    this.problem = null;
    this.inserting = false;
    this.scroll = ScrollHandle.new();
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Filter words…" });
    this.input.on("change", (_e, cx) => {
      this.query = this.input.value();
      this.at = 0;
      this.scroll.scroll_to_item(0);
      cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.pick(this.shown()[this.at], cx));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.load(cx);
  }

  load(cx) {
    if (!this.terminal) {
      this.loading = false;
      this.problem = "Focus a terminal, then press the key again.";
      return;
    }
    this.loading = true;
    const lines = this.withScrollback ? SCROLLBACK_LINES : 0;
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["read", this.terminal, "--lines", String(lines)]);
        if (r.code === 0) {
          this.words = extractWordsNewestFirst(r.stdout);
          this.problem = null;
        } else {
          this.problem = `hc read ${this.terminal} failed: ${(r.stderr || r.stdout).trim()}`;
        }
      } catch (e) {
        this.problem = `hc read ${this.terminal} failed: ${e}`;
      }
      this.loading = false;
      this.at = 0;
      cx.notify();
    });
  }

  shown() {
    return filterWords(this.words, this.query);
  }

  close() {
    closeOverlay(props().overlay);
  }

  pick(word, cx) {
    if (!word || this.inserting) return;
    this.inserting = true;
    cx.notify();
    cx.spawn(async (cx) => {
      const previous = await clipboardTextOrNull();
      if (!(await copiedToClipboard(word))) {
        notify({
          title: "screen-word",
          body: "No clipboard tool found. Install wl-clipboard, xclip or xsel.",
          level: "error",
        });
        this.close();
        return;
      }
      await cx.sleep(COPY_SETTLE_MS);
      run("terminal.paste");
      await cx.sleep(PASTE_SETTLE_MS);
      if (previous !== null) await copiedToClipboard(previous);
      this.close();
    });
  }

  move(by, total) {
    if (!total) return;
    this.at = (this.at + by + total) % total;
    this.scroll.scroll_to_item(this.at);
  }

  onKey(e, cx) {
    const total = Math.min(this.shown().length, MAX_ROWS_SHOWN);
    const ctrl = e.modifiers.control;
    if (e.key === "escape") this.close();
    else if (e.key === "down" || (ctrl && (e.key === "n" || e.key === "j"))) this.move(1, total);
    else if (e.key === "up" || (ctrl && (e.key === "p" || e.key === "k"))) this.move(-1, total);
    else if (ctrl && e.key === "s") {
      this.withScrollback = !this.withScrollback;
      this.load(cx);
    } else return;
    cx.stop_propagation();
    cx.notify();
  }

  render() {
    const t = theme();
    const matches = this.shown();
    const rows = matches.slice(0, MAX_ROWS_SHOWN);
    this.at = Math.min(this.at, Math.max(0, rows.length - 1));
    const status = this.loading
      ? "reading…"
      : `${matches.length}/${this.words.length}${this.withScrollback ? " · scrollback" : ""}`;

    const row = (word, i) =>
      h_flex()
        .id(`sw-${i}`)
        .h(ROW_HEIGHT)
        .flex_none()
        .px(10)
        .items_center()
        .rounded(6)
        .font_family(settings().font_family ?? "JetBrains Mono")
        .text_color(t.foreground)
        .cursor_pointer()
        .when(i === this.at, (el) => el.bg(t.selected))
        .hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => this.pick(word, cx))
        .child(div().truncate().child(word));

    const body = this.problem
      ? div().p(10).text_color(t.muted).child(this.problem)
      : !this.loading && rows.length === 0
        ? div().p(10).text_color(t.dim).child(this.words.length ? "No word matches." : "No words on screen.")
        : v_flex()
            .id("sw-list")
            .h(Math.min(rows.length, VISIBLE_ROWS) * ROW_HEIGHT)
            .flex_none()
            .overflow_y_scrollbar()
            .track_scroll(this.scroll)
            .children(rows.map(row))
            .when(matches.length > rows.length, (el) =>
              el.child(div().p(8).text_size(11).text_color(t.dim).child(`${matches.length - rows.length} more; type to narrow`)));

    return v_flex()
      .id("screen-word")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.onKey(e, cx))
      .w_full()
      .min_h(0)
      .p(14)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .when(this.inserting, (el) => el.opacity(0.5))
      .child(
        h_flex()
          .items_center()
          .gap(8)
          .child(div().flex_1().text_size(14).font_semibold().text_color(t.foreground).child("Insert a word"))
          .child(div().text_size(11).text_color(t.dim).child(status)),
      )
      .child(
        h_flex().h(34).flex_none().px(10).items_center().rounded(8).border_1().border_color(t.accent).bg(t.background)
          .child(Input.new(this.input).flex_1().h_full().text_size(13).text_color(t.foreground)),
      )
      .child(body)
      .child(div().flex_none().text_size(11).text_color(t.dim).child("↑↓ move · Enter insert · Ctrl+S scrollback · Esc close"));
  }
}
