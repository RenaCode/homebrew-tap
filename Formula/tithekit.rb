# frozen_string_literal: true

# TitheKit formula. This PR stays a draft until the first release exists.
#
# The sha256 is set BY HAND after each tag, from the `.sha256` file of the release
# (`tithekit-<version>-arm64.tar.gz.sha256` in RenaCode/tithekit-releases); the release does not change this file.
# Order after the tag: put the sum here, `brew audit --strict --new renacode/tap/tithekit`, `brew install` from the real
# URL, `brew test`, then take the PR out of draft. Use final tags only (v0.1.0), never a -rc.N prerelease.
#
# The archives are published by the `release` job of RenaCode/tithekit to the public repository
# RenaCode/tithekit-releases, which holds only the binary archives.
class Tithekit < Formula
  desc "Resource budget and priority queue for CI, builds and agents on a Mac"
  homepage "https://tithekit.com"
  url "https://github.com/RenaCode/tithekit-releases/releases/download/v0.1.1/tithekit-0.1.1-arm64.tar.gz"
  version "0.1.1"
  sha256 "d309efabe3a7484d1fc6591e5324bb33a8d8c3d3848df4a790963d178a56a98b"
  license :cannot_represent # proprietary binary license: LICENSE-BINARY.md in the archive

  depends_on arch: :arm64
  # The CI runner takes its GitHub token from `gh auth token`.
  depends_on "gh"
  depends_on macos: :sequoia

  # The release binaries are signed (the runner with the Virtualization entitlement): do not let `brew` strip them.
  # `test do` checks that the entitlement survived the installation.
  skip_clean "bin"

  def install
    bin.install "bin/tithekit", "bin/tithekitd", "bin/tithekit-runner"
    pkgshare.install Dir["share/tithekit/*"]
    doc.install "README.md", "LICENSE-BINARY.md", "SECURITY.md", "CHANGELOG.md"
    doc.install "docs" # the links of the README resolve against docs/ next to it
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

      CI runner (optional, experimental in 0.1.0): it needs `gh auth login` (admin:org for an organization), a macOS VM image
      and a LaunchAgent of its own; `brew services` does not manage it. Import the image with
        tithekit-runner image import <image-dir> <name>
      then follow #{pkgshare}/runner.md and #{pkgshare}/vm.md. The LaunchAgent template is
      #{pkgshare}/com.renacode.tithekit-runner.plist (replace __HOME__ with your home and __BIN__ with #{HOMEBREW_PREFIX}/bin;
      keep ProcessType Standard). Use the runner only for trusted, private repositories.

      Menu bar app (optional): download TitheKit-#{version}.zip from
        https://github.com/RenaCode/tithekit-releases/releases/tag/v#{version}
      Unpack it to ~/Applications and add it to System Settings > General > Login Items. 0.1.0 is not notarized:
      download it with `curl -L -O <url>`, or clear the quarantine flag after unzipping:
        xattr -dr com.apple.quarantine ~/Applications/TitheKit.app

      Uninstall: `brew uninstall` does not stop what you started yourself. Before it, stop the runner and the daemon
      (`launchctl bootout gui/$(id -u)/com.renacode.tithekit-runner`, `brew services stop tithekit`), delete the runner's
      LaunchAgent plist in ~/Library/LaunchAgents, run `tithekit shims remove`, and remove agent hooks you added. For the
      space back, delete ~/Library/Application Support/TitheKit (the VM store, tens of GB) and ~/Library/Logs/TitheKit.
      Details: "Uninstall" in #{doc}/README.md.

      Proprietary software of RenaCode (#{doc}/LICENSE-BINARY.md); the community edition is free.
    EOS
  end

  test do
    ENV["SLOT_STATE"] = testpath/"slot.json"
    ENV["TITHEKIT_LOG_DIR"] = testpath/"logs"
    assert_match "usage: tithekit", shell_output("#{bin}/tithekit 2>&1", 2)
    system bin/"tithekit", "status"
    system bin/"tithekit", "light", "--", "true"
    assert_match "job.end", shell_output("#{bin}/tithekit logs --component cli")

    # The runner cannot create VMs without the Virtualization entitlement.
    entitlements = shell_output("codesign -d --entitlements - #{bin}/tithekit-runner 2>&1")
    assert_match "com.apple.security.virtualization", entitlements

    # `image` needs no settings.
    assert_match "usage: tithekit-runner image", shell_output("#{bin}/tithekit-runner image 2>&1", 2)

    # With complete settings but without a gh it can run, the runner refuses to start and says what to do
    # (it is not the missing SCOPE that is tested here).
    ENV["TITHEKIT_RUNNER_SCOPE"] = "repo:o/r"
    ENV["TITHEKIT_RUNNER_REPOS"] = "o/r"
    ENV["TITHEKIT_RUNNER_LABELS"] = "self-hosted"
    ENV["TITHEKIT_RUNNER_IMAGE"] = "none"
    ENV["TITHEKIT_RUNNER_GH"] = testpath/"no-such-gh"
    assert_match "brew install gh", shell_output("#{bin}/tithekit-runner 2>&1", 2)
  end
end
