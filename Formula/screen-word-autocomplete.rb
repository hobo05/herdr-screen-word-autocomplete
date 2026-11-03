class ScreenWordAutocomplete < Formula
  desc "Pick a word from your herdr pane's output with fzf and insert it"
  homepage "https://github.com/hobo05/herdr-screen-word-autocomplete"
  url "https://github.com/hobo05/herdr-screen-word-autocomplete/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "85e21cdabab37647301e58d26458109cf748a8b779b14a45252c54c4f2cb9d27"
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
