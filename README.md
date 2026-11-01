# Arch Config

Arch Config installs a portable Openbox/BSPWM desktop rice on an existing Arch Linux installation. A normal `./install.sh` installs the required package set and restores the reviewed configuration bundle in `rice-config/`. This is not an operating-system installer.

The public bundle contains the rice's shell, window-manager, panel, launcher, GTK, Eww, and theme configuration, QMMP configured with the selected Lain skin, and the two wallpapers referenced by the setup. It excludes personal documents, project directories, credentials, local application state, and VM artifacts. The private dated archive used while preparing this curated bundle is ignored by Git and is not required to install the rice.

## What the installer does

- Runs `pacman -Syu --needed` with the selected package list in one transaction, avoiding unsupported partial upgrades.
- Installs the rice packages from official repositories, including QMMP, Vim, and Neovim (`nvim`), and Eww from the AUR, building `yay` if needed.
- Validates the bundle's SHA-256 manifest before restoring files.
- Backs up conflicting destination files under `~/.local/state/archconfig-backups/` and leaves unrelated files in place.
- Supports `--dry-run`, `--noconfirm`, `--config-only`, `--packages-only`, and `--config-dir DIR`.

The installer runs as a regular user and requests `sudo` for package operations. Prompts stay enabled by default; `--noconfirm` skips supported pacman, makepkg, and yay confirmations, including the package transaction review. It cannot bypass `sudo` password authentication. It does not configure a bootloader, GPU driver, login manager, or default shell. Openbox is the default session in `.xinitrc`; select BSPWM with `RICE_WM=bspwm startx`.

## Packages

The installer installs these official repository packages:

- **Base and shell:** `sudo`, `base-devel`, `git`, `curl`, `wget`, `python`, `zsh`, `eza`, `fzf`, `ripgrep`, `jq`, `vim`, `neovim` (provides the `nvim` command).
- **Window managers and desktop tools:** `openbox`, `obconf-qt`, `bspwm`, `sxhkd`, `kitty`, `rofi`, `picom`, `polybar`, `feh`, `wmctrl`, `xdotool`, `xclip`, `maim`.
- **Xorg:** `xorg-server`, `xorg-xinit`, `xorg-xrandr`, `xorg-xset`, `xorg-xsetroot`, `xorg-xprop`, `xorg-xrdb`.
- **Services and audio:** `dbus`, `dunst`, `libnotify`, `slock`, `playerctl`, `alsa-utils`, `pavucontrol`, `pipewire`, `pipewire-audio`, `pipewire-pulse`, `wireplumber`.
- **Desktop integration:** `xsettingsd`, `polkit`, `polkit-gnome`, `gvfs`, `gvfs-mtp`, `thunar`, `xdg-utils`, `xdg-user-dirs`, `xdg-desktop-portal-gtk`, `qmmp`.
- **Themes and fonts:** `breeze-gtk`, `breeze-icons`, `breeze-cursors`, `fontconfig`, `noto-fonts`, `ttf-jetbrains-mono-nerd`, `ttf-nerd-fonts-symbols`.

Eww is installed from the AUR. If `yay` is missing, the script builds it from the AUR using the installed `git` and `base-devel` packages. The QMMP configuration selects the bundled `Twilight_a_Lain_Skin` skin.

## Requirements

- Arch Linux with network access and a regular user with `sudo` privileges.
- Bash, Python 3, `pacman`, and `sudo` already available before starting the script.

Do not run the installer as root. Review `./install.sh --dry-run` before applying changes. The installer installs `git` and `base-devel` itself when it proceeds with package installation.

## Usage

From a clone of this repository:

```bash
./install.sh --dry-run
./install.sh
```

To skip package-manager confirmation prompts, use `./install.sh --noconfirm`. `sudo` may still request your password.

Options:

- `--dry-run`: prints the package and configuration plan and exits without making changes.
- `--noconfirm`: bypasses supported pacman, makepkg, and yay confirmation prompts, including review of the package transaction. Sudo may still ask for your password.
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

The Zsh configuration includes the workflow shortcuts from the original setup (`openlab`, `ip4`, `venv`, `ports`, `translate`, `box`, `cheatengine`, `lain`, `rst`, `bspwmrc`, `sxhkdrc`, `polybarc`, `mkt`, and `pentestgpt`), plus the `ls`, `ll`, `la`, and `tree` helpers. Paths use `$HOME`; local projects, VPN profiles, and credentials remain outside the bundle. Some shortcuts require those local tools or files to exist. The manifest covers only files inside `rice-config/`. The root `.gitignore` excludes dated personal archives, `vm-test/`, generated output, environment files, keys, and caches. Never copy personal backup data into the public bundle.

## Scope and limitations

This installs desktop configuration and its package dependencies; it is not a full system image or rollback mechanism. Existing settings that differ are saved before replacement, but package installation can upgrade the system. Monitor layouts, hardware-specific GPU metrics, and optional home-folder actions can vary by machine. Project-specific Zsh shortcuts work when the corresponding local tools or folders exist. The Eww GPU widget displays `N/A` when the graphics driver does not expose a supported utilization counter.

No `LICENSE` file is included. Publishing this repository on GitHub does not by itself grant permission to reuse or redistribute its code.
