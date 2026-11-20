class ScreenWordAutocomplete < Formula
  desc "Pick a word from a herdr-app terminal's output and insert it"
  homepage "https://github.com/hobo05/herdr-screen-word-autocomplete"
  url "https://github.com/hobo05/herdr-screen-word-autocomplete/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "6fb467688eb90f2c0a2a26370e9828bc71377a5db32a65652cb80750593c2fb4"
  license "MIT"
  head "https://github.com/hobo05/herdr-screen-word-autocomplete.git", branch: "main"

  depends_on "jq"

  def install
    bin.install "bin/screen-word"
    pkgshare.install "mod"
  end

  def caveats
    <<~EOS
      screen-word is a herdr-app mod (https://herdr.dev). Install it and bind
      Cmd+; on macOS, Alt+; on Linux:
        screen-word setup

      Before brew uninstall, remove the binding and the mod:
        screen-word uninstall

      On Linux, the word is pasted through the clipboard, so install
      wl-clipboard (Wayland), xclip or xsel.
    EOS
  end

  test do
    assert_match "screen-word #{version}", shell_output("#{bin}/screen-word --version")
    assert_path_exists pkgshare/"mod/main.js"
    (testpath/"herdr-app/keys.json").write("{}\n")
    ENV["HERDR_APP_HOME"] = testpath/"herdr-app"
    system bin/"screen-word", "setup", "--key", "alt-x"
    assert_equal "mod.open:screen-word",
                 shell_output("jq -r '.terminal[\"alt-x\"]' #{testpath}/herdr-app/keys.json").strip
  end
end
