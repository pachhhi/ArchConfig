#!/usr/bin/env bash
# Arch Linux rice installer. Run as your regular desktop user, never with sudo.
set -Eeuo pipefail
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
RICE_CONFIG="$BASE/rice-config"
DRY=0; CONFIG_ONLY=0; PACKAGES_ONLY=0
usage() {
  cat <<'HELP'
Usage: ./install.sh [--dry-run] [--config-only | --packages-only] [--config-dir DIR]
  --dry-run        Print the plan; no writes, sudo, network or package changes.
  --config-only    Install the rice configuration without installing packages.
  --packages-only  Install rice packages without restoring configuration.
  --config-dir DIR Use another rice bundle containing home/ and manifest.json.
Run as a regular user with sudo privileges. Package-manager and AUR prompts stay enabled.
HELP
}
while (($#)); do
  case "$1" in
    --dry-run) DRY=1;;
    --config-only) CONFIG_ONLY=1;;
    --packages-only) PACKAGES_ONLY=1;;
    --config-dir) (($#>=2)) || { usage; exit 2; }; RICE_CONFIG=$2; shift;;
    -h|--help) usage; exit 0;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2;;
  esac
  shift
done
((CONFIG_ONLY && PACKAGES_ONLY)) && { echo 'Choose only one partial mode.' >&2; exit 2; }
if ((!PACKAGES_ONLY)); then
  [[ -d "$RICE_CONFIG/home" && -f "$RICE_CONFIG/manifest.json" ]] || {
    printf 'Invalid rice configuration bundle: %s\n' "$RICE_CONFIG" >&2
    exit 1
  }
fi
REPO=(sudo base-devel git curl wget python zsh eza fzf ripgrep jq
  openbox obconf-qt bspwm sxhkd kitty rofi picom polybar feh wmctrl xdotool xclip maim
  xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xsetroot xorg-xprop xorg-xrdb
  dbus dunst libnotify slock playerctl alsa-utils pavucontrol
  pipewire pipewire-audio pipewire-pulse wireplumber
  xsettingsd polkit polkit-gnome gvfs gvfs-mtp thunar xdg-utils xdg-user-dirs xdg-desktop-portal-gtk
  qmmp breeze-gtk breeze-icons breeze-cursors fontconfig noto-fonts
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols)
AUR=(eww)
printf 'Rice configuration: %s\nDestination: %s\n' "$RICE_CONFIG" "$HOME"
if ((!CONFIG_ONLY)); then
  printf '\nOfficial packages:\n%s\n' "${REPO[*]}"
  printf '\nRice AUR packages (+ yay if missing):\n%s\n' "${AUR[*]}"
  echo 'A full pacman -Syu upgrade precedes installation (no partial upgrades).'
fi
if ((!PACKAGES_ONLY)); then
  echo 'Restore: reviewed rice configs, QMMP with the selected Lain skin, Eww scripts, Openbox theme, and wallpapers.'
  echo 'Existing differing files are saved under ~/.local/state/archconfig-backups/.'
fi
((DRY)) && { echo 'DRY RUN: no changes made.'; exit 0; }
((EUID!=0)) || { echo 'Run as your regular user, not root/sudo.' >&2; exit 1; }
[[ -f /etc/arch-release ]] || { echo 'This installer targets Arch Linux.' >&2; exit 1; }
if ((!CONFIG_ONLY)); then
  command -v sudo >/dev/null || { echo 'sudo is required.' >&2; exit 1; }
  if ! sudo -n true 2>/dev/null; then
    sudo -v
  fi
  sudo pacman -Syu --needed "${REPO[@]}"
  if ! command -v yay >/dev/null; then
    BUILD_DIR=$(mktemp -d -t archconfig-yay.XXXXXXXX)
    trap '[[ -z ${BUILD_DIR:-} ]] || rm -rf -- "$BUILD_DIR"' EXIT
    git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
    (cd "$BUILD_DIR/yay" && makepkg -si)
  fi
  yay -S --needed "${AUR[@]}"
fi
if ((!PACKAGES_ONLY)); then
  command -v python3 >/dev/null || { echo 'python3 is required for restoration.' >&2; exit 1; }
  python3 "$BASE/restore-rice.py" "$RICE_CONFIG" "$HOME"
  command -v fc-cache >/dev/null && fc-cache -f "$HOME/.local/share/fonts"
  command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications"
fi
cat <<'DONE'
Finished. Log out and choose Openbox in your existing login manager, or run startx from a TTY.
No login manager, shell change, GPU driver or bootloader configuration was forced.
To choose Zsh as your login shell: chsh -s /usr/bin/zsh
Check monitor-specific settings and optional folder shortcuts in the installed configuration.
The public bundle contains only the reviewed rice files; personal data and local projects are excluded.
DONE
