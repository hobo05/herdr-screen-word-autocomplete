# screen-word-autocomplete

Press **Alt+;** in a [herdr](https://herdr.dev) pane, fuzzy-pick any word from that pane's recent output, and have it typed at your cursor. It works at a shell prompt and inside full-screen programs such as Claude Code, vim or less.

```
$ git status
        modified:   src/main/java/com/example/PaymentRouter.java
$ git diff ▮          ← Alt+; → type "Rout" → Enter
$ git diff src/main/java/com/example/PaymentRouter.java
```

Works on macOS and Linux.

## Install

```sh
brew tap hobo05/screen-word https://github.com/hobo05/screen-word-autocomplete
brew trust --formula hobo05/screen-word/screen-word-autocomplete
brew install screen-word-autocomplete
```

Homebrew refuses formulae from third-party taps until you trust them, hence the `brew trust` step.

This installs the `screen-word` command and pulls in `fzf`. You also need herdr on your `PATH`.

## Set up

```sh
screen-word setup
```

```
Set up screen-word for:
  1) herdr  popup on alt+; that works in any herdr pane, including Claude Code and vim
  2) zsh    widget on alt+; at the zsh prompt
  3) both   herdr on alt+; and zsh on alt+'
Choose [1-3]:
```

Or skip the menu with `screen-word setup herdr`, `screen-word setup zsh` or `screen-word setup both`. Running a setup again leaves an existing binding alone.

### herdr binding (recommended)

```sh
screen-word setup herdr            # binds alt+;
screen-word setup herdr --key alt+o
```

This adds a popup binding to `~/.config/herdr/config.toml` (or `$HERDR_CONFIG_PATH`) and reloads the running herdr server. When you press the key, herdr opens a popup with fzf over the words of the pane underneath. Pick one and it is typed into that pane.

### zsh widget

```sh
screen-word setup zsh              # binds alt+;
screen-word setup zsh --key alt+o
```

This adds a block to `~/.zshrc` (or `$ZDOTDIR/.zshrc`) that loads the widget, so the key opens fzf inline at the zsh prompt instead of in a popup. Open a new shell to use it. `--key` takes `alt+<char>`, `ctrl+<char>`, or a bindkey string such as `^[o`.

The widget still reads the herdr pane, so it only finds words inside herdr. It works only at the zsh prompt, not inside programs such as Claude Code or vim. herdr sees keys before zsh, which is why `both` puts zsh on alt+' rather than alt+;.

To load it by hand instead, add this to `.zshrc`:

```sh
SCREEN_WORD_KEY='^[;'   # optional, this is the default
eval "$(screen-word init zsh)"
```

### Uninstall

`brew uninstall` only removes the files brew installed, not what `screen-word setup` added to your configs. Remove those first:

```sh
screen-word uninstall          # herdr and zsh; or: screen-word uninstall herdr|zsh
brew uninstall screen-word-autocomplete
```

This removes the herdr binding (and reloads herdr) and the `.zshrc` block that setup wrote, and leaves the rest of each file as it was. Lines you wrote by hand, such as your own `eval "$(screen-word init zsh)"`, are left for you to remove; uninstall says so when it finds any.

If you uninstall with brew first, the `.zshrc` block does nothing, because it checks that `screen-word` exists. The herdr key would open a popup that fails, so delete the `[[keys.command]]` block that mentions `screen-word` from herdr's `config.toml`.

### macOS

Your terminal must send Option as Alt, or Option+; types a character instead:

- Ghostty: `macos-option-as-alt = true`
- iTerm2: Profiles → Keys → Left Option key → Esc+
- Terminal.app: Profiles → Keyboard → Use Option as Meta key

## Commands

| Command | What it does |
|---|---|
| `screen-word popup` | Pick from the pane under a herdr popup and type the word into it. Used by the herdr binding. |
| `screen-word pick [--pane ID]` | Pick a word with fzf and print it. |
| `screen-word words [--pane ID]` | Print the candidate words, newest first. |
| `screen-word words --stdin` | Read the text from stdin instead of a pane. |
| `screen-word setup` | Ask whether to set up herdr, zsh or both. |
| `screen-word setup herdr [--key K]` | Add the popup binding to herdr's config. |
| `screen-word setup zsh [--key K]` | Add the widget loader to `.zshrc`. |
| `screen-word setup both` | herdr on alt+; and zsh on alt+'. |
| `screen-word uninstall [herdr\|zsh\|both]` | Remove what setup added (default both). |
| `screen-word init zsh` | Print the zsh widget. |

`--lines N` sets how many recent lines are read (default 300). The pane defaults to `$HERDR_ACTIVE_PANE_ID`, then `$HERDR_PANE_ID`.

Words are split on whitespace. Surrounding quotes and brackets, and trailing punctuation such as `,` `:` `.`, are trimmed. Words shorter than 3 characters are dropped, and each word is listed once.

## Develop

```sh
bats test/
```

The script sticks to bash 3.2 and awk features shared by BWK awk (macOS), gawk, mawk and busybox awk.

## Release

1. Set `VERSION` in `bin/screen-word`, commit, then tag and push: `git tag v0.1.0 && git push origin main v0.1.0`.
2. Get the tarball checksum:
   `curl -fsSL https://github.com/hobo05/screen-word-autocomplete/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256`
3. Update `url` and `sha256` in `Formula/screen-word-autocomplete.rb`, commit and push.
4. Check it: `brew update && brew upgrade screen-word-autocomplete && brew test screen-word-autocomplete`.
