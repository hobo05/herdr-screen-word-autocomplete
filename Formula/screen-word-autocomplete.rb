class ScreenWordAutocomplete < Formula
  desc "Pick a word from your herdr pane's output with fzf and insert it"
  homepage "https://github.com/hobo05/herdr-screen-word-autocomplete"
  url "https://github.com/hobo05/herdr-screen-word-autocomplete/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "caf4284ad54dbfff6a9d0f948c084a44b208bc9089d5003a40d8f0749ad9733c"
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
