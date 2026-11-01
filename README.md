# Arch Config

Arch Config installs a portable Openbox/BSPWM desktop rice on an existing Arch Linux installation. A normal `./install.sh` installs the required package set and restores the reviewed configuration bundle in `rice-config/`. This is not an operating-system installer.

The public bundle contains the rice's shell, window-manager, panel, launcher, GTK, Eww, and theme configuration, QMMP configured with the selected Lain skin, and the two wallpapers referenced by the setup. It excludes personal documents, project directories, credentials, local application state, and VM artifacts. The private dated archive used while preparing this curated bundle is ignored by Git and is not required to install the rice.

## What the installer does

- Runs a full `pacman -Syu` before installing packages, avoiding unsupported partial upgrades.
- Installs the rice packages from official repositories, including QMMP, Vim, and Neovim (`nvim`), and Eww from the AUR, building `yay` if needed.
- Validates the bundle's SHA-256 manifest before restoring files.
- Backs up conflicting destination files under `~/.local/state/archconfig-backups/` and leaves unrelated files in place.
- Supports `--dry-run`, `--noconfirm`, `--config-only`, `--packages-only`, and `--config-dir DIR`.

The installer runs as a regular user and requests `sudo` for package operations. Prompts stay enabled by default; `--noconfirm` skips package-manager and AUR confirmations where supported. It cannot bypass `sudo` password authentication. It does not configure a bootloader, GPU driver, login manager, or default shell. Openbox is the default session in `.xinitrc`; select BSPWM with `RICE_WM=bspwm startx`.

## Requirements

- Arch Linux with network access and a regular user with `sudo` privileges.
- Bash, Python 3, `pacman`, and `sudo`.
- `git` and Arch build tools if `yay` is not already installed.

Do not run the installer as root. Review the package prompts and the dry-run plan before applying changes.

## Usage

From a clone of this repository:

```bash
./install.sh --dry-run
./install.sh
```

Options:

- `--dry-run`: prints the package and configuration plan and exits without making changes.
- `--noconfirm`: bypasses supported pacman, makepkg, and yay confirmation prompts; package operations may proceed without a final review. Sudo may still ask for your password.
- `--config-only`: restores the rice bundle without installing packages.
- `--packages-only`: installs packages without restoring configuration.
- `--config-dir DIR`: uses another reviewed bundle containing `home/` and `manifest.json`.
- `--help`: prints command syntax.

After installation, log out and select Openbox in an existing login manager, or start X from a TTY. To use Zsh as the login shell, review and run `chsh -s /usr/bin/zsh` yourself.

## Repository layout

- `install.sh`: package installation and default full setup flow.
- `restore-rice.py`: manifest verification, per-file restore, and conflict backups.
- `rice-config/home/`: allowlisted, portable rice configuration and assets, including the selected QMMP skin.
- `tools/update-rice-manifest.py`: regenerates the bundle integrity manifest after reviewed edits.

The Zsh configuration includes the workflow shortcuts from the original setup, using portable home-relative paths; local projects, VPN profiles, and credentials remain outside the bundle. The manifest covers only files inside `rice-config/`. The root `.gitignore` excludes dated personal archives, `vm-test/`, generated output, environment files, keys, and caches. Never copy personal backup data into the public bundle.

## Scope and limitations

This installs desktop configuration and its package dependencies; it is not a full system image or rollback mechanism. Existing settings that differ are saved before replacement, but package installation can upgrade the system. Monitor layouts, hardware-specific GPU metrics, and optional home-folder actions can vary by machine. Project-specific Zsh shortcuts work when the corresponding local tools or folders exist. The Eww GPU widget displays `N/A` when the graphics driver does not expose a supported utilization counter.

No `LICENSE` file is included. Publishing this repository on GitHub does not by itself grant permission to reuse or redistribute its code.
