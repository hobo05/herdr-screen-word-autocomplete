# screen-word zsh widget: picks a word from this herdr pane's output and inserts it at the cursor.
# `screen-word setup zsh` adds the loader to .zshrc, or load it yourself: eval "$(screen-word init zsh)"
# Set SCREEN_WORD_KEY before loading to change the key (default: Alt+; as '^[;').
# Inside herdr, a `screen-word setup herdr` binding on the same key takes the key first
# and also works in full-screen programs; this widget is for plain zsh prompts.

screen-word-widget() {
  local word
  word=$(screen-word pick 2>/dev/null) || { zle reset-prompt; return 0; }
  [[ -n $word ]] && LBUFFER+=$word
  zle reset-prompt
}
zle -N screen-word-widget
bindkey "${SCREEN_WORD_KEY:-^[;}" screen-word-widget
