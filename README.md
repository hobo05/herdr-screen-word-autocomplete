# herdr-screen-word-autocomplete

Press **Cmd+;** on macOS (**Alt+;** on Linux) in a [herdr](https://herdr.dev) pane, fuzzy-pick any word visible in that pane, and have it typed at your cursor. It works at a shell prompt and inside full-screen programs such as Claude Code, vim or less.

```
$ git status
        modified:   src/main/java/com/example/PaymentRouter.java
$ git diff ▮          ← Cmd+; (Alt+; on Linux) → type "Rout" → Enter
$ git diff src/main/java/com/example/PaymentRouter.java
```

Works on macOS and Linux.

## Install

```sh
brew tap hobo05/screen-word https://github.com/hobo05/herdr-screen-word-autocomplete
brew trust --formula hobo05/screen-word/screen-word-autocomplete
brew install screen-word-autocomplete
```

Homebrew refuses formulae from third-party taps until you trust them, hence the `brew trust` step. `brew uninstall` also drops the trust, so run `brew trust` again before reinstalling.

This installs the `screen-word` command and pulls in `fzf`. You also need herdr on your `PATH`.

## Set up

```sh
screen-word setup                  # binds cmd+; on macOS, alt+; on Linux
screen-word setup --key alt+o
```

`setup` picks the chord the OS can deliver by default: Cmd+; on macOS, where Option would compose `…` unless every terminal is configured to send Alt, and Alt+; on Linux, which has no Cmd key. Pass `--key` to choose another chord.

This adds a popup binding to `~/.config/herdr/config.toml` (or `$HERDR_CONFIG_PATH`) and reloads the running herdr server. The binding is wrapped in `# >>> screen-word >>>` / `# <<< screen-word <<<` comments so it is easy to find and remove by hand. When you press the key, herdr opens a popup with fzf over the words of the pane underneath. Pick one and it is typed into that pane. Running setup again leaves an existing binding alone.

herdr sees the key before the program in the pane, which is why it works inside Claude Code, vim and other full-screen programs as well as at a shell prompt.

### Uninstall

`brew uninstall` only removes the files brew installed, not the binding `screen-word setup` added. Remove it first:

```sh
screen-word uninstall
brew uninstall screen-word-autocomplete
```

This removes the binding, reloads herdr, and leaves the rest of the config as it was. If you uninstall with brew first, the key would open a popup that fails, so delete the `[[keys.command]]` block between the `# >>> screen-word >>>` and `# <<< screen-word <<<` comments in herdr's `config.toml`. `screen-word doctor` reports a binding whose command is gone, as well as duplicate bindings.

### macOS

The default Cmd+; needs no terminal setup.

Only if you bind Alt+; with `screen-word setup --key alt+;` must your terminal send Option as Alt, or Option+; types `…` instead:

- Ghostty: `macos-option-as-alt = true` (already the default on U.S. Standard and U.S. International layouts)
- iTerm2: Profiles → Keys → Left Option key → Esc+
- Terminal.app: Profiles → Keyboard → Use Option as Meta key

## Commands

| Command | What it does |
|---|---|
| `screen-word setup [--key K]` | Add the popup binding to herdr's config: Cmd+; on macOS, Alt+; elsewhere. |
| `screen-word uninstall` | Remove the popup binding. |
| `screen-word doctor` | Report a binding whose command is gone, and duplicate bindings. |
| `screen-word popup` | Pick from the pane under a herdr popup and type the word into it. Used by the binding. |
| `screen-word pick [--pane ID]` | Pick a word with fzf and print it. |
| `screen-word words [--pane ID]` | Print the candidate words, newest first. |
| `screen-word words --stdin` | Read the text from stdin instead of a pane. |

By default only what is visible in the pane is read, so the picker offers the words you can see. `--lines N` reads the last N lines of output instead, including scrollback. The pane defaults to `$HERDR_ACTIVE_PANE_ID`, then `$HERDR_PANE_ID`.

To use scrollback from the keybinding, add `--lines` to its command in herdr's `config.toml`, for example `command = "/opt/homebrew/bin/screen-word popup --lines 300"`.

Words are split on whitespace. Surrounding quotes and brackets, and trailing punctuation such as `,` `:` `.`, are trimmed. Words shorter than 3 characters are dropped, and each word is listed once.

## Develop

```sh
bats test/
```

The script sticks to bash 3.2 and awk features shared by BWK awk (macOS), gawk, mawk and busybox awk.

## Release

1. Set `VERSION` in `bin/screen-word`, commit, then tag and push: `git tag -a v0.4.0 -m v0.4.0 && git push origin main v0.4.0`.
2. Get the tarball checksum:
   `curl -fsSL https://github.com/hobo05/herdr-screen-word-autocomplete/archive/refs/tags/v0.4.0.tar.gz | shasum -a 256`
3. Update `url` and `sha256` in `Formula/screen-word-autocomplete.rb`, commit and push.
4. Check it: `brew update && brew upgrade screen-word-autocomplete && brew test screen-word-autocomplete`.
