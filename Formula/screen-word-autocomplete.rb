class ScreenWordAutocomplete < Formula
  desc "Pick a word from your herdr pane's output with fzf and insert it"
  homepage "https://github.com/hobo05/screen-word-autocomplete"
  url "https://github.com/hobo05/screen-word-autocomplete/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"
  head "https://github.com/hobo05/screen-word-autocomplete.git", branch: "main"

  depends_on "fzf"

  def install
    bin.install "bin/screen-word"
    (share/"screen-word").install "share/screen-word/screen-word.zsh"
  end

  def caveats
    <<~EOS
      screen-word reads panes through herdr (https://herdr.dev), which must be on your PATH.

      Bind Alt+; in herdr (works in any pane, including full-screen programs):
        screen-word setup herdr

      Or bind it in zsh only, by adding this to ~/.zshrc:
        eval "$(screen-word init zsh)"

      On macOS, make your terminal send Option as Alt (Ghostty: macos-option-as-alt = true).
    EOS
  end

  test do
    assert_match "screen-word #{version}", shell_output("#{bin}/screen-word --version")
    assert_equal "gamma\nbeta\nalpha\n",
                 pipe_output("#{bin}/screen-word words --stdin", "alpha beta\ngamma\n")
    assert_match "bindkey", shell_output("#{bin}/screen-word init zsh")
  end
end
