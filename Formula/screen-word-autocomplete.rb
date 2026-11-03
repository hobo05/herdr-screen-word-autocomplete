class ScreenWordAutocomplete < Formula
  desc "Pick a word from your herdr pane's output with fzf and insert it"
  homepage "https://github.com/hobo05/herdr-screen-word-autocomplete"
  url "https://github.com/hobo05/herdr-screen-word-autocomplete/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "be33b242efedfd2ec804ac15a11819c0eb6f2449ea6b06cb5ea9abf45003e64b"
  license "MIT"
  head "https://github.com/hobo05/herdr-screen-word-autocomplete.git", branch: "main"

  depends_on "fzf"

  def install
    bin.install "bin/screen-word"
  end

  def caveats
    <<~EOS
      screen-word reads panes through herdr (https://herdr.dev), which must be on your PATH.

      Bind Alt+; in herdr:
        screen-word setup

      Before brew uninstall, remove that binding:
        screen-word uninstall

      On macOS, make your terminal send Option as Alt (Ghostty: macos-option-as-alt = true).
    EOS
  end

  test do
    assert_match "screen-word #{version}", shell_output("#{bin}/screen-word --version")
    assert_equal "gamma\nbeta\nalpha\n",
                 pipe_output("#{bin}/screen-word words --stdin", "alpha beta\ngamma\n")
  end
end
