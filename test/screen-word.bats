#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SW="$ROOT/bin/screen-word"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$FAKE_BIN"
  export HERDR_CONFIG_PATH="$BATS_TEST_TMPDIR/herdr/config.toml"
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

fake_uname() {
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$1" >"$FAKE_BIN/uname"
  chmod +x "$FAKE_BIN/uname"
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

@test "words reads only the visible part of the pane named by HERDR_PANE_ID" {
  fake_herdr
  HERDR_PANE_ID=w1:p1 run "$SW" words
  [ "$status" -eq 0 ]
  [ "$output" = $'line\noutput\nnewer\nhere\nwords\nold' ]
  grep -q '^pane read w1:p1 --source visible$' "$BATS_TEST_TMPDIR/herdr.calls"
}

@test "words --lines reads that many recent lines, including scrollback" {
  fake_herdr
  HERDR_PANE_ID=w1:p1 run "$SW" words --lines 500
  [ "$status" -eq 0 ]
  grep -q '^pane read w1:p1 --source recent-unwrapped --lines 500$' "$BATS_TEST_TMPDIR/herdr.calls"
}

@test "words --lines rejects a value that is not a number" {
  run "$SW" words --lines lots
  [ "$status" -eq 1 ]
  [[ "$output" == *"--lines must be a number"* ]]
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

@test "setup adds one popup binding and is idempotent" {
  fake_herdr
  run "$SW" setup --key 'alt+x'
  [ "$status" -eq 0 ]
  grep -q 'key = "alt+x"' "$HERDR_CONFIG_PATH"
  grep -q "command = \"$ROOT/bin/screen-word popup\"" "$HERDR_CONFIG_PATH"
  run "$SW" setup
  [[ "$output" == *"already bound"* ]]
  [ "$(grep -c 'keys.command' "$HERDR_CONFIG_PATH")" -eq 1 ]
}

@test "setup defaults to cmd+; on macOS" {
  fake_herdr
  fake_uname Darwin
  run "$SW" setup
  [ "$status" -eq 0 ]
  grep -q 'key = "cmd+;"' "$HERDR_CONFIG_PATH"
}

@test "setup defaults to alt+; elsewhere" {
  fake_herdr
  fake_uname Linux
  run "$SW" setup
  [ "$status" -eq 0 ]
  grep -q 'key = "alt+;"' "$HERDR_CONFIG_PATH"
}

@test "setup still accepts the herdr target from earlier versions" {
  fake_herdr
  run "$SW" setup herdr
  [ "$status" -eq 0 ]
  grep -q 'keys.command' "$HERDR_CONFIG_PATH"
}

@test "setup rejects a target other than herdr" {
  run "$SW" setup zsh
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: screen-word setup"* ]]
  [ ! -f "$HERDR_CONFIG_PATH" ]
}

@test "setup binds the symlinked path, not its target" {
  fake_herdr
  ln -s "$SW" "$FAKE_BIN/screen-word"
  run "$FAKE_BIN/screen-word" setup
  [ "$status" -eq 0 ]
  grep -q "command = \"$FAKE_BIN/screen-word popup\"" "$HERDR_CONFIG_PATH"
}

@test "uninstall restores the config exactly, keeping other bindings" {
  fake_herdr
  mkdir -p "$(dirname "$HERDR_CONFIG_PATH")"
  cat >"$HERDR_CONFIG_PATH" <<'EOF'
onboarding = false

[[keys.command]]
key = "prefix+g"
type = "popup"
command = "lazygit"

[ui.toast]
delivery = "terminal"
EOF
  cp "$HERDR_CONFIG_PATH" "$BATS_TEST_TMPDIR/before.toml"
  "$SW" setup
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed the screen-word binding"* ]]
  cmp "$HERDR_CONFIG_PATH" "$BATS_TEST_TMPDIR/before.toml"
}

@test "uninstall removes a binding placed between other tables" {
  mkdir -p "$(dirname "$HERDR_CONFIG_PATH")"
  cat >"$HERDR_CONFIG_PATH" <<'EOF'
[[keys.command]]
key = "alt+;"
type = "popup"
command = "/opt/bin/screen-word popup"

[[keys.command]]
key = "prefix+g"
command = "lazygit"
EOF
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  ! grep -q 'screen-word' "$HERDR_CONFIG_PATH"
  grep -q 'lazygit' "$HERDR_CONFIG_PATH"
  [ "$(grep -c 'keys.command' "$HERDR_CONFIG_PATH")" -eq 1 ]
}

@test "uninstall keeps a symlinked config a symlink" {
  mkdir -p "$(dirname "$HERDR_CONFIG_PATH")"
  printf 'onboarding = false\n' >"$BATS_TEST_TMPDIR/real.toml"
  ln -s "$BATS_TEST_TMPDIR/real.toml" "$HERDR_CONFIG_PATH"
  "$SW" setup
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  [ -L "$HERDR_CONFIG_PATH" ]
  [ "$(cat "$BATS_TEST_TMPDIR/real.toml")" = "onboarding = false" ]
}

@test "uninstall is safe to repeat and creates no files when nothing is set up" {
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"No screen-word binding"* ]]
  [ ! -f "$HERDR_CONFIG_PATH" ]
}
