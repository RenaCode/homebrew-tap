# RenaCode Homebrew tap

Homebrew packages for [RenaCode](https://github.com/RenaCode) apps.

```sh
brew install --cask renacode/tap/cloudmachine
```

Homebrew finds this repository by its name: `renacode/tap` stands for
`github.com/RenaCode/homebrew-tap`. Nothing needs to be added first —
the first install taps it automatically, and `brew upgrade` picks up new
versions.

## Packages

| Cask | What it is |
|---|---|
| [`cloudmachine`](Casks/cloudmachine.rb) | [CloudMachine](https://github.com/RenaCode/CloudMachine) — Time Machine backups to Google Drive, with a menu-bar app. macOS 14+, Apple Silicon and Intel. |

After installing, open the app (`open -a CloudMachine`); its window walks
through the rest of the setup. See the
[CloudMachine README](https://github.com/RenaCode/CloudMachine#getting-started).

## How this repository is updated

Nobody edits the casks here by hand. Each release of an app regenerates its
cask from a template in the app's own repository and pushes it here — for
CloudMachine, `packaging/homebrew/cloudmachine.rb.in` and
`.github/workflows/release.yml`. A change made directly in this repository is
overwritten by the next release; change the template instead.

## Notes

- **Not notarised.** The apps are signed with a self-signed certificate, not an
  Apple Developer ID, so the cask removes the quarantine flag after install.
- **Uninstalling CloudMachine** does not stop its background agents or delete
  its upload buffer in `~/.cloudmachine`, which may hold backups not yet on
  Google Drive. Run `cloudmachine-agent prepare-shutdown` first; `brew info
  --cask renacode/tap/cloudmachine` shows the details.
