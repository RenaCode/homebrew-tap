# frozen_string_literal: true

# Formula template. The release of RenaCode/tithekit substitutes the version in the URL and the sha256.
# The archive host is an owner decision; the URL below is the recommended one (public repository
# RenaCode/tithekit-releases holding only the binary archives).
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
    bin.install "bin/tithekit", "bin/tithekitd"
    pkgshare.install Dir["share/tithekit/*"]
    doc.install "README.md"
  end

  # Optional: `brew services start tithekit` runs the daemon (the CLI works without it).
  service do
    run [opt_bin/"tithekitd"]
    keep_alive true
    process_type :interactive
    log_path var/"log/tithekitd.log"
    error_log_path var/"log/tithekitd.log"
  end

  def caveats
    <<~EOS
      The daemon is optional: `tithekit` works without it. To run it at login:
        brew services start tithekit
      See #{pkgshare}/daemon.md. Proprietary software of RenaCode; the community edition is free.
    EOS
  end

  test do
    ENV["SLOT_STATE"] = testpath/"slot.json"
    assert_match "usage: tithekit", shell_output("#{bin}/tithekit 2>&1", 2)
    system bin/"tithekit", "status"
    system bin/"tithekit", "light", "--", "true"
  end
end
