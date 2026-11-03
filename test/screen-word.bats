#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SW="$ROOT/bin/screen-word"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$FAKE_BIN"
  export HERDR_CONFIG_PATH="$BATS_TEST_TMPDIR/herdr/config.toml"
  export ZDOTDIR="$BATS_TEST_TMPDIR/zdot"
  mkdir -p "$ZDOTDIR"
  unset HERDR_PANE_ID HERDR_ACTIVE_PANE_ID
}

fake_herdr() {
  cat >"$FAKE_BIN/herdr" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$BATS_TEST_TMPDIR/herdr.calls"
case "$1 $2" in
  "pane read") printf 'old words here\nnewer output line\n' ;;
esac
EOF
  chmod +x "$FAKE_BIN/herdr"
  PATH="$FAKE_BIN:$PATH"
}

@test "words lists newest first, once each, skipping short words" {
  run "$SW" words --stdin <<<$'alpha beta ab\ngamma alpha'
  [ "$status" -eq 0 ]
  [ "$output" = $'alpha\ngamma\nbeta' ]
}

@test "words trims surrounding quotes, brackets and trailing punctuation" {
  run "$SW" words --stdin <<<$'"quoted" (paren) <angle> path/to/file.java:42: end.'
  [ "$status" -eq 0 ]
  [ "$output" = $'end\npath/to/file.java:42\nangle\nparen\nquoted' ]
}

@test "words reads the pane named by HERDR_PANE_ID through herdr" {
  fake_herdr
  HERDR_PANE_ID=w1:p1 run "$SW" words
  [ "$status" -eq 0 ]
  [ "$output" = $'line\noutput\nnewer\nhere\nwords\nold' ]
  grep -q 'pane read w1:p1 --source recent-unwrapped --lines 300' "$BATS_TEST_TMPDIR/herdr.calls"
}

@test "words without a pane fails with a hint" {
  run "$SW" words
  [ "$status" -eq 1 ]
  [[ "$output" == *"no herdr pane"* ]]
}

@test "popup types the picked word into the active pane" {
  fake_herdr
  cat >"$FAKE_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
grep -m1 output
EOF
  chmod +x "$FAKE_BIN/fzf"
  HERDR_ACTIVE_PANE_ID=w1:p2 run "$SW" popup
  [ "$status" -eq 0 ]
  grep -q '^pane send-text w1:p2 output$' "$BATS_TEST_TMPDIR/herdr.calls"
}

@test "popup sends nothing when fzf is cancelled" {
  fake_herdr
  printf '#!/usr/bin/env bash\nexit 130\n' >"$FAKE_BIN/fzf"
  chmod +x "$FAKE_BIN/fzf"
  HERDR_ACTIVE_PANE_ID=w1:p2 run "$SW" popup
  [ "$status" -eq 0 ]
  ! grep -q 'send-text' "$BATS_TEST_TMPDIR/herdr.calls"
}

@test "setup herdr adds one popup binding and is idempotent" {
  fake_herdr
  run "$SW" setup herdr --key 'alt+x'
  [ "$status" -eq 0 ]
  grep -q 'key = "alt+x"' "$HERDR_CONFIG_PATH"
  grep -q "command = \"$ROOT/bin/screen-word popup\"" "$HERDR_CONFIG_PATH"
  run "$SW" setup herdr
  [[ "$output" == *"already bound"* ]]
  [ "$(grep -c 'keys.command' "$HERDR_CONFIG_PATH")" -eq 1 ]
}

@test "setup herdr binds the symlinked path, not its target" {
  fake_herdr
  ln -s "$SW" "$FAKE_BIN/screen-word"
  run "$FAKE_BIN/screen-word" setup herdr
  [ "$status" -eq 0 ]
  grep -q "command = \"$FAKE_BIN/screen-word popup\"" "$HERDR_CONFIG_PATH"
}

@test "setup zsh adds the loader to .zshrc once" {
  run "$SW" setup zsh
  [ "$status" -eq 0 ]
  grep -q 'SCREEN_WORD_KEY="\^\[;"' "$ZDOTDIR/.zshrc"
  grep -q 'eval "$(screen-word init zsh)"' "$ZDOTDIR/.zshrc"
  run "$SW" setup zsh
  [[ "$output" == *"already loaded"* ]]
  [ "$(grep -c 'screen-word init zsh' "$ZDOTDIR/.zshrc")" -eq 1 ]
}

@test "setup zsh rejects a key it cannot translate" {
  run "$SW" setup zsh --key 'f5'
  [ "$status" -eq 1 ]
  [[ "$output" == *"zsh key must be"* ]]
  [ ! -f "$ZDOTDIR/.zshrc" ]
}

@test "the .zshrc block binds the chosen key in zsh, including a quote key" {
  command -v zsh >/dev/null || skip "zsh not installed"
  ln -s "$SW" "$FAKE_BIN/screen-word"
  run "$SW" setup zsh --key "alt+\""
  [ "$status" -eq 0 ]
  run env PATH="$FAKE_BIN:$PATH" zsh -ic "bindkey '^[\"'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"screen-word-widget"* ]]
}

@test "setup menu choice 1 sets up herdr only" {
  fake_herdr
  run "$SW" setup <<<"1"
  [ "$status" -eq 0 ]
  grep -q 'key = "alt+;"' "$HERDR_CONFIG_PATH"
  [ ! -f "$ZDOTDIR/.zshrc" ]
}

@test "setup menu choice 2 sets up zsh only" {
  run "$SW" setup <<<"2"
  [ "$status" -eq 0 ]
  grep -q 'SCREEN_WORD_KEY="\^\[;"' "$ZDOTDIR/.zshrc"
  [ ! -f "$HERDR_CONFIG_PATH" ]
}

@test "setup menu choice 3 puts herdr on alt+; and zsh on alt+'" {
  fake_herdr
  run "$SW" setup <<<"3"
  [ "$status" -eq 0 ]
  grep -q 'key = "alt+;"' "$HERDR_CONFIG_PATH"
  grep -q "SCREEN_WORD_KEY=\"^\['\"" "$ZDOTDIR/.zshrc"
}

@test "setup menu rejects an unknown choice and changes nothing" {
  run "$SW" setup <<<"9"
  [ "$status" -eq 1 ]
  [[ "$output" == *"expected 1, 2 or 3"* ]]
  [ ! -f "$HERDR_CONFIG_PATH" ]
  [ ! -f "$ZDOTDIR/.zshrc" ]
}

@test "init zsh prints the widget, also through a symlink" {
  ln -s "$SW" "$FAKE_BIN/screen-word"
  run "$FAKE_BIN/screen-word" init zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"zle -N screen-word-widget"* ]]
}

@test "the zsh widget loads in zsh and binds Alt+;" {
  command -v zsh >/dev/null || skip "zsh not installed"
  run zsh -fic "eval \"\$($SW init zsh)\"; bindkey '^[;'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"screen-word-widget"* ]]
}
