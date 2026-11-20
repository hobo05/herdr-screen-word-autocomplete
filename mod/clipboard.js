import { exec } from "herdr";

const READ_CLIPBOARD_TEXT = `
if command -v pbpaste >/dev/null 2>&1; then exec pbpaste
elif [ -n "\${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then exec wl-paste --no-newline --type text
elif command -v xclip >/dev/null 2>&1; then exec xclip -selection clipboard -out
elif command -v xsel >/dev/null 2>&1; then exec xsel --clipboard --output
else exit 127
fi`;

const WRITE_CLIPBOARD_DETACHED = `
if command -v pbcopy >/dev/null 2>&1; then printf %s "$1" | pbcopy
elif [ -n "\${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then printf %s "$1" | wl-copy >/dev/null 2>&1
elif command -v xclip >/dev/null 2>&1; then printf %s "$1" | xclip -selection clipboard >/dev/null 2>&1
elif command -v xsel >/dev/null 2>&1; then printf %s "$1" | xsel --clipboard --input >/dev/null 2>&1
else exit 127
fi`;

export async function clipboardTextOrNull() {
  try {
    const r = await exec("sh", ["-c", READ_CLIPBOARD_TEXT], { timeout: 3000 });
    return r.code === 0 ? r.stdout : null;
  } catch {
    return null;
  }
}

export async function copiedToClipboard(text) {
  try {
    const r = await exec("sh", ["-c", WRITE_CLIPBOARD_DETACHED, "sh", text], { timeout: 3000 });
    return r.code === 0;
  } catch {
    return false;
  }
}
