#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SW="$ROOT/bin/screen-word"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$FAKE_BIN"
  export HERDR_APP_HOME="$BATS_TEST_TMPDIR/herdr-app"
  export HERDR_CONFIG_PATH="$BATS_TEST_TMPDIR/herdr/config.toml"
  KEYS="$HERDR_APP_HOME/keys.json"
  MOD="$HERDR_APP_HOME/mods/screen-word"
  mkdir -p "$HERDR_APP_HOME"
  cat >"$KEYS" <<'EOF'
{
  "global": {
    "ctrl-shift-t": "tab.new"
  },
  "terminal": {
    "ctrl-shift-c": "terminal.copy"
  }
}
EOF
}

fake_uname() {
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$1" >"$FAKE_BIN/uname"
  chmod +x "$FAKE_BIN/uname"
  PATH="$FAKE_BIN:$PATH"
}

fake_herdr_app() {
  printf '#!/usr/bin/env bash\necho "$*" >>"$BATS_TEST_TMPDIR/herdr-app.calls"\n' >"$FAKE_BIN/herdr-app"
  printf '#!/usr/bin/env bash\n' >"$FAKE_BIN/hc"
  printf '#!/usr/bin/env bash\ncat >/dev/null\n' >"$FAKE_BIN/xclip"
  chmod +x "$FAKE_BIN/herdr-app" "$FAKE_BIN/hc" "$FAKE_BIN/xclip"
  PATH="$FAKE_BIN:$PATH"
}

binding() {
  jq -r --arg k "$1" '.terminal[$k] // empty' "$KEYS"
}

@test "setup binds the key in the terminal section and links the mod" {
  run "$SW" setup --key alt-x
  [ "$status" -eq 0 ]
  [ "$(binding alt-x)" = "mod.open:screen-word" ]
  [ -L "$MOD" ]
  [ "$(cd "$MOD" && pwd -P)" = "$ROOT/mod" ]
}

@test "setup keeps the other bindings" {
  "$SW" setup --key alt-x
  [ "$(jq -r '.global["ctrl-shift-t"]' "$KEYS")" = "tab.new" ]
  [ "$(binding ctrl-shift-c)" = "terminal.copy" ]
}

@test "setup accepts herdr's plus spelling of a key" {
  run "$SW" setup --key 'alt+x'
  [ "$status" -eq 0 ]
  [ "$(binding alt-x)" = "mod.open:screen-word" ]
}

@test "setup defaults to cmd-; on macOS" {
  fake_uname Darwin
  run "$SW" setup
  [ "$status" -eq 0 ]
  [ "$(binding 'cmd-;')" = "mod.open:screen-word" ]
}

@test "setup defaults to alt-; elsewhere" {
  fake_uname Linux
  run "$SW" setup
  [ "$status" -eq 0 ]
  [ "$(binding 'alt-;')" = "mod.open:screen-word" ]
}

@test "setup is idempotent" {
  "$SW" setup --key alt-x
  run "$SW" setup --key alt-y
  [ "$status" -eq 0 ]
  [[ "$output" == *"already bound"* ]]
  [ "$(grep -c 'mod.open:screen-word' "$KEYS")" -eq 1 ]
  [ -L "$MOD" ]
}

@test "setup refuses a key that is already bound to something else" {
  run "$SW" setup --key ctrl-shift-t
  [ "$status" -eq 1 ]
  [[ "$output" == *"already bound to tab.new"* ]]
  ! grep -q screen-word "$KEYS"
  [ ! -e "$MOD" ]
}

@test "setup refuses to replace a mod folder it did not make" {
  mkdir -p "$MOD"
  run "$SW" setup --key alt-x
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not a link"* ]]
  ! grep -q screen-word "$KEYS"
}

@test "setup needs herdr-app to have written keys.json" {
  rm "$KEYS"
  run "$SW" setup
  [ "$status" -eq 1 ]
  [[ "$output" == *"start herdr-app once"* ]]
}

@test "setup links the mod installed beside a brew-style bin" {
  local prefix="$BATS_TEST_TMPDIR/prefix"
  mkdir -p "$prefix/bin" "$prefix/share/screen-word-autocomplete"
  cp "$SW" "$prefix/bin/screen-word"
  cp -R "$ROOT/mod" "$prefix/share/screen-word-autocomplete/mod"
  run "$prefix/bin/screen-word" setup --key alt-x
  [ "$status" -eq 0 ]
  [ "$(readlink "$MOD")" = "$prefix/share/screen-word-autocomplete/mod" ]
}

@test "setup removes the old herdr (TUI) binding" {
  mkdir -p "$(dirname "$HERDR_CONFIG_PATH")"
  cat >"$HERDR_CONFIG_PATH" <<'EOF'
onboarding = false

# >>> screen-word >>>
[[keys.command]]
key = "alt+;"
type = "popup"
command = "/opt/homebrew/bin/screen-word popup"
# <<< screen-word <<<
EOF
  run "$SW" setup --key alt-x
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed the old herdr (TUI) binding"* ]]
  [ "$(cat "$HERDR_CONFIG_PATH")" = "onboarding = false" ]
}

@test "uninstall removes the binding and the mod link, keeping other bindings" {
  "$SW" setup --key alt-x
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed the screen-word binding"* ]]
  ! grep -q screen-word "$KEYS"
  [ "$(binding ctrl-shift-c)" = "terminal.copy" ]
  [ "$(jq -r '.global["ctrl-shift-t"]' "$KEYS")" = "tab.new" ]
  [ ! -e "$MOD" ]
}

@test "uninstall removes a binding placed in the global section" {
  jq '.global["alt-z"] = "mod.open:screen-word"' "$KEYS" >"$KEYS.new" && mv "$KEYS.new" "$KEYS"
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  ! grep -q screen-word "$KEYS"
}

@test "uninstall keeps a symlinked keys.json a symlink" {
  mv "$KEYS" "$BATS_TEST_TMPDIR/real-keys.json"
  ln -s "$BATS_TEST_TMPDIR/real-keys.json" "$KEYS"
  "$SW" setup --key alt-x
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  [ -L "$KEYS" ]
  ! grep -q screen-word "$BATS_TEST_TMPDIR/real-keys.json"
}

@test "uninstall leaves a mod folder it did not make" {
  mkdir -p "$MOD"
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"Left $MOD in place"* ]]
  [ -d "$MOD" ]
}

@test "uninstall is safe to repeat" {
  run "$SW" uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"No screen-word binding"* ]]
}

@test "doctor reports a healthy setup and checks the mod with herdr-app" {
  fake_herdr_app
  "$SW" setup --key alt-x
  run "$SW" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *'Binding: "alt-x" in terminal'* ]]
  [[ "$output" == *"Everything is in place."* ]]
  grep -q "^check $MOD$" "$BATS_TEST_TMPDIR/herdr-app.calls"
}

@test "doctor flags a missing binding and mod" {
  fake_herdr_app
  run "$SW" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"no binding"* ]]
  [[ "$output" == *"missing: the mod"* ]]
}

@test "doctor flags duplicate bindings" {
  fake_herdr_app
  "$SW" setup --key alt-x
  jq '.global["alt-z"] = "mod.open:screen-word"' "$KEYS" >"$KEYS.new" && mv "$KEYS.new" "$KEYS"
  run "$SW" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"2 bindings found"* ]]
}

@test "doctor flags a leftover herdr (TUI) binding" {
  fake_herdr_app
  "$SW" setup --key alt-x
  mkdir -p "$(dirname "$HERDR_CONFIG_PATH")"
  printf '[[keys.command]]\nkey = "alt+;"\ncommand = "/x/screen-word popup"\n' >"$HERDR_CONFIG_PATH"
  run "$SW" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"old herdr (TUI) binding"* ]]
}
