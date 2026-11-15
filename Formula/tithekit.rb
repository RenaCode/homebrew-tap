# frozen_string_literal: true

# Formula template. The release of RenaCode/tithekit substitutes the version in the URL and the sha256
# (this PR stays a draft until the first release exists: the sha256 below is a placeholder).
# The archives are published by the `release` job of RenaCode/tithekit to the public repository
# RenaCode/tithekit-releases, which holds only the binary archives.
class Tithekit < Formula
  desc "Resource budget and priority queue for CI, builds and agents on a Mac"
  homepage "https://tithekit.com"
  url "https://github.com/RenaCode/tithekit-releases/releases/download/v0.1.0/tithekit-0.1.0-arm64.tar.gz"
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license :cannot_represent

  depends_on arch: :arm64
  depends_on macos: :sequoia

  def install
    bin.install "bin/tithekit", "bin/tithekitd", "bin/tithekit-runner"
    pkgshare.install Dir["share/tithekit/*"]
    doc.install "README.md"
  end

  # Optional: `brew services start tithekit` runs the daemon (the CLI works without it). The daemon writes its own
  # structured log to ~/Library/Logs/TitheKit/daemon.log; the file below only receives what it prints on stderr.
  # launchd creates the directory.
  service do
    run [opt_bin/"tithekitd"]
    keep_alive true
    process_type :interactive
    log_path "#{Dir.home}/Library/Logs/TitheKit/daemon.stderr"
    error_log_path "#{Dir.home}/Library/Logs/TitheKit/daemon.stderr"
  end

  def caveats
    <<~EOS
      Logs (JSON, one directory): ~/Library/Logs/TitheKit/
        tithekit logs --since 1d --level warn    # --follow, --component daemon|runner|app|cli, --json
      Examples and the list of events: #{pkgshare}/logi.md

      The daemon is optional: `tithekit` works without it. To run it at login:
        brew services start tithekit

      Menu bar app (optional): download TitheKit-#{version}.zip from
        https://github.com/RenaCode/tithekit-releases/releases/tag/v#{version}
      unpack it to ~/Applications and add it to System Settings > General > Login Items.

      CI runner (optional, needs a configured image and GitHub login): #{pkgshare}/runner.md. A LaunchAgent template is
      #{pkgshare}/com.renacode.tithekit-runner.plist (replace __HOME__ with your home and __BIN__ with #{HOMEBREW_PREFIX}/bin).
      Keep ProcessType Standard in it. `brew services` does not manage the runner: it needs settings of your own.

      Proprietary software of RenaCode; the community edition is free.
    EOS
  end

  test do
    ENV["SLOT_STATE"] = testpath/"slot.json"
    ENV["TITHEKIT_LOG_DIR"] = testpath/"logs"
    assert_match "usage: tithekit", shell_output("#{bin}/tithekit 2>&1", 2)
    system bin/"tithekit", "status"
    system bin/"tithekit", "light", "--", "true"
    assert_match "job.end", shell_output("#{bin}/tithekit logs --component cli")
    assert_match "TITHEKIT_RUNNER_SCOPE is required", shell_output("#{bin}/tithekit-runner 2>&1", 2)
  end
end
