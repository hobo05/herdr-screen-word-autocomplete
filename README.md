# herdr-screen-word-autocomplete

Press **Cmd+;** on macOS (**Alt+;** on Linux) in a [herdr-app](https://herdr.dev) terminal, fuzzy-pick any word visible in that terminal, and have it inserted at your cursor. It works at a shell prompt and inside full-screen programs such as Claude Code, vim or less.

```
$ git status
        modified:   src/main/java/com/example/PaymentRouter.java
$ git diff ▮          ← Cmd+; (Alt+; on Linux) → type "Rout" → Enter
$ git diff src/main/java/com/example/PaymentRouter.java
```

Works on macOS and Linux. It needs herdr-app, the desktop app. The older `herdr` terminal multiplexer is no longer supported.

## Install

```sh
brew tap hobo05/screen-word https://github.com/hobo05/herdr-screen-word-autocomplete
brew trust --formula hobo05/screen-word/screen-word-autocomplete
brew install screen-word-autocomplete
```

Homebrew refuses formulae from third-party taps until you trust them, hence the `brew trust` step. `brew uninstall` also drops the trust, so run `brew trust` again before reinstalling.

This installs the `screen-word` command, the herdr-app mod it sets up, and `jq`. herdr-app and its `hc` command must be installed. On Linux you also need a clipboard tool: `wl-clipboard` on Wayland, `xclip` or `xsel` on X11. macOS has `pbcopy` built in.

## Set up

```sh
screen-word setup                  # binds cmd-; on macOS, alt-; on Linux
screen-word setup --key alt-o
```

`setup` does two things:

1. It links herdr-app's `mods/screen-word` folder to the installed mod, in `~/.config/herdr-app` or `$HERDR_APP_HOME`.
2. It adds `"<key>": "mod.open:screen-word"` to the `terminal` section of herdr-app's `keys.json`.

herdr-app reloads both at once, so the key works without a restart. Start herdr-app at least once before running setup, so that `keys.json` exists. Setup refuses a key that is already bound to something else. Running it again leaves an existing binding alone.

`setup` picks the chord the OS can deliver by default: Cmd+; on macOS, where Option would type `…` on many keyboard layouts, and Alt+; on Linux, which has no Cmd key. Pass `--key` to choose another chord, in herdr-app's spelling (`ctrl-shift-y`). `alt+;` is accepted too.

If you used an earlier version with the `herdr` multiplexer, `setup` also removes the old binding from `~/.config/herdr/config.toml`.

### Uninstall

`brew uninstall` only removes the files brew installed, not the binding or the mod link that `screen-word setup` added. Remove them first:

```sh
screen-word uninstall
brew uninstall screen-word-autocomplete
```

This removes the `mod.open:screen-word` entry from `keys.json` and the `mods/screen-word` link, and leaves the rest of `keys.json` as it was. If you uninstalled with brew first, delete that entry and the dangling link by hand. `screen-word doctor` reports both.

## Using it

Press the key while a terminal has focus. A popup lists every word on that terminal's screen, newest first. Type to filter, then press Enter or click a word to insert it.

| Key | What it does |
|---|---|
| Typing | Filter. Prefix matches first, then substring, then scattered letters. Lowercase ignores case. |
| ↑ ↓, Ctrl+N Ctrl+P, Ctrl+J Ctrl+K | Move the selection. |
| Enter | Insert the selected word. |
| Ctrl+S | Include the last 1000 lines of scrollback, or go back to the screen only. |
| Esc | Close without inserting. |

Words are split on whitespace. Surrounding quotes and brackets, and trailing punctuation such as `,` `:` `.`, are trimmed. Words shorter than 3 characters are dropped, and each word is listed once.

herdr-app has no command that types text into a terminal, so the mod copies the word to the clipboard, runs herdr-app's paste, then puts your previous clipboard text back. Programs see a normal paste. A clipboard that held something other than text, such as an image, is left holding the word.

## Commands

| Command | What it does |
|---|---|
| `screen-word setup [--key K]` | Link the mod and bind it: Cmd+; on macOS, Alt+; elsewhere. |
| `screen-word uninstall` | Remove the binding and the mod link. |
| `screen-word doctor` | Check the binding, the mod (with `herdr-app check`), `hc`, the clipboard tool, and any leftover `herdr` binding. |

## Develop

```sh
bats test/
node --test test/*.test.mjs
herdr-app check mod
```

To try changes in the running app, link the checkout instead of the brew copy: `screen-word uninstall`, then `bin/screen-word setup`. herdr-app reloads the mod whenever a file in `mod/` is saved.

`bin/screen-word` sticks to bash 3.2 and awk features shared by BWK awk (macOS), gawk, mawk and busybox awk. The mod is plain JavaScript for herdr-app: `mod/words.js` has no herdr imports, so node can test it.

## Release

1. Set `VERSION` in `bin/screen-word`, commit, then tag and push: `git tag -a v0.4.0 -m v0.4.0 && git push origin main v0.4.0`.
2. Get the tarball checksum:
   `curl -fsSL https://github.com/hobo05/herdr-screen-word-autocomplete/archive/refs/tags/v0.4.0.tar.gz | shasum -a 256`
3. Update `url` and `sha256` in `Formula/screen-word-autocomplete.rb`, commit and push.
4. Check it: `brew update && brew upgrade screen-word-autocomplete && brew test screen-word-autocomplete`.
