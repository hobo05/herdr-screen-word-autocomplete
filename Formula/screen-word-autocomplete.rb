class ScreenWordAutocomplete < Formula
  desc "Pick a word from your herdr pane's output with fzf and insert it"
  homepage "https://github.com/hobo05/screen-word-autocomplete"
  url "https://github.com/hobo05/screen-word-autocomplete/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "0ba2291363fb0304610edbd23ee4470692c5575c03455477d5ff20dd67b95551"
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

      Choose herdr, zsh or both:
        screen-word setup

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
