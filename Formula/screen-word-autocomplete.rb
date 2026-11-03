class ScreenWordAutocomplete < Formula
  desc "Pick a word from your herdr pane's output with fzf and insert it"
  homepage "https://github.com/hobo05/herdr-screen-word-autocomplete"
  url "https://github.com/hobo05/herdr-screen-word-autocomplete/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "6fb467688eb90f2c0a2a26370e9828bc71377a5db32a65652cb80750593c2fb4"
  license "MIT"
  head "https://github.com/hobo05/herdr-screen-word-autocomplete.git", branch: "main"

  depends_on "fzf"

  def install
    bin.install "bin/screen-word"
  end

  def caveats
    <<~EOS
      screen-word reads panes through herdr (https://herdr.dev), which must be on your PATH.

      Bind it in herdr (Cmd+; on macOS, Alt+; on Linux):
        screen-word setup

      Before brew uninstall, remove that binding:
        screen-word uninstall

      On macOS, Cmd+; needs no terminal setup. If you bind Alt+; instead, make your
      terminal send Option as Alt (Ghostty: macos-option-as-alt = true).
    EOS
  end

  test do
    assert_match "screen-word #{version}", shell_output("#{bin}/screen-word --version")
    assert_equal "gamma\nbeta\nalpha\n",
                 pipe_output("#{bin}/screen-word words --stdin", "alpha beta\ngamma\n")
  end
end
