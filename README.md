# Arch Config

Arch Config contains scripts for installing a curated Arch Linux desktop package set and safely restoring a reviewed configuration snapshot into a user's home directory. It is designed for an existing Arch installation, not as an operating-system installer.

The scripts and documentation are public-source candidates. The original personal configuration snapshot and VM test directory are intentionally excluded: they can contain machine-specific settings, local paths, logs, test credentials, or keys. A clone therefore needs a separate, reviewed snapshot before running the restore mode.

## Capabilities

- Install a curated set of official repository packages with `pacman`.
- Build `yay` from the AUR when it is missing, then install a curated AUR package list.
- Back up `/etc/pacman.conf` before enabling the `multilib` repository when needed.
- Perform a full `pacman -Syu` before package installation to avoid unsupported partial upgrades.
- Restore files from a snapshot after checking its manifest and SHA-256 hashes.
- Adapt archived `/home/<user>` paths to the selected destination home.
- Back up existing conflicting files before replacing them; keep destination files that are not part of the snapshot.
- Offer `--dry-run`, `--config-only`, `--packages-only`, and `--snapshot DIR` modes.

## How the scripts fit together

```text
install.sh
  ├─ validates options and snapshot (restore modes)
  ├─ optionally configures multilib and installs official/AUR packages
  └─ calls restore-rice.py for the configuration restore

restore-rice.py
  ├─ verifies snapshot hashes and manifest paths
  ├─ maps home files and supported shared themes/fonts into the user's home
  ├─ backs up conflicting destination files
  └─ writes a restore report
```

## Design decisions and trade-offs

These explanations describe trade-offs visible in the current code; they are not claims about the original historical motivation for each decision.

| Decision | Practical reason | Trade-off |
| --- | --- | --- |
| Run as a regular user and request `sudo` only for package/system configuration steps | Keeps the restore in the logged-in user's context and avoids running the whole script as root. | The user needs sudo access and must review package prompts and system changes. |
| Keep `pacman`, `makepkg`, and `yay` prompts enabled | Lets the user inspect package/AUR operations and resolve conflicts instead of silently accepting them. | Installation is not fully unattended. |
| Run a full system upgrade before installing packages | Arch does not support partial upgrades; the package operation stays aligned with current repositories. | This can update the existing system, not just add the desktop packages. |
| Back up `pacman.conf` before enabling `multilib` | Makes the repository configuration recoverable if the edit causes trouble. | The script still changes system package configuration and requires careful review. |
| Verify all manifest paths and file hashes before restoring | Rejects path traversal and detects a modified or incomplete snapshot before applying files. | A suitable snapshot and its manifest must be supplied separately. |
| Back up each conflicting destination file and preserve unrelated destination files | Makes restoration reversible and avoids treating the snapshot as a complete replacement for the home directory. | It is a per-file restore, not a complete disk image or full-system rollback. |
| Install the custom theme and saved fonts under the user's data directory | Avoids overwriting shared system theme/font files. | Some desktop components still depend on system packages installed separately. |
| Do not configure the bootloader, drivers, login manager, or default shell | Limits the installer to the desktop setup and avoids high-impact machine-specific changes. | Those parts remain the user's responsibility. |
| Keep a dry-run mode before any privileged or network operation | Gives the user a way to inspect the selected package and restore plan first. | Dry-run does not prove that packages are currently available or that a later restore will succeed. |

## Requirements

- Arch Linux with a working network connection for package installation.
- A regular user with `sudo` privileges; do not run `install.sh` as root.
- Bash, Python 3, `pacman`, and `sudo`.
- `git` and the usual Arch build toolchain for building `yay` if it is not installed.
- A reviewed snapshot for restore modes, with a `home/` directory and `manifest.json`. The restorer also recognizes supported paths under `system/usr/share/themes` and `system/usr/share/fonts`.

## Snapshot and privacy boundary

The snapshot used on the original machine is not included in this repository. It contains personal desktop configuration and machine-specific settings. VM test artifacts are also omitted; they include local logs and SSH material. The root `.gitignore` excludes dated snapshots, `vm-test/`, generated `artifacts/`, databases, environment files, keys, and caches.

To use your own snapshot, first create and review one with the structure expected by `restore-rice.py`, then pass its path explicitly:

```bash
./install.sh --dry-run --snapshot /path/to/reviewed-snapshot
```

After reviewing the plan, omit `--dry-run` to apply it. The original snapshot is available only in the developer's local working copy and is not a portable example or part of the public source. The repository does not yet include a snapshot-generation command.

## Usage

Run from the project directory as a regular user:

```bash
./install.sh --dry-run --snapshot /path/to/reviewed-snapshot
./install.sh --snapshot /path/to/reviewed-snapshot
```

Options:

- `--dry-run`: prints the plan and exits before writes, `sudo`, network access, or package changes.
- `--config-only`: restores configuration without installing packages; needs Python 3 and a snapshot.
- `--packages-only`: installs packages without restoring configuration; does not require a snapshot.
- `--snapshot DIR`: selects a snapshot containing `home/` and `manifest.json`.
- `--help`: prints the command syntax.

The normal package list is maintained in the `REPO` and `AUR` arrays in `install.sh`. The package inventory files from the original machine are intentionally not part of this repository and are not used as an installation manifest.

After a restore, review the generated `RESTORE-REPORT.txt`, log out, and select Openbox in an existing login manager, or start X from a TTY. The installer does not install or enable a login manager and does not change the default shell. If you want Zsh as your login shell, run `chsh -s /usr/bin/zsh` yourself after reviewing the change.

## Verification status

Project notes record a successful dry run, restoration into a temporary home, and a real install in a clean Arch Linux virtual machine. Those checks were not rerun for this documentation commit. The virtual machine did not render the configured Eww dashboard widgets, and physical monitor modes cannot be validated in a VM. A fresh install can also encounter AUR package changes over time.

To repeat the non-destructive preview:

```bash
./install.sh --dry-run --snapshot /path/to/reviewed-snapshot
```

## License

No `LICENSE` file is included. Publishing this repository on GitHub does not by itself grant permission to reuse or redistribute its code.
