#!/usr/bin/env bash
# Arch Linux rice installer. Run as your regular desktop user, never with sudo.
set -Eeuo pipefail
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
SNAPSHOT="$BASE/2026-10-31_04-46-31"
DRY=0; CONFIG_ONLY=0; PACKAGES_ONLY=0
usage() {
  cat <<'HELP'
Usage: ./install.sh [--dry-run] [--config-only | --packages-only] [--snapshot DIR]
  --dry-run        Print the plan; no writes, sudo, network or package changes.
  --config-only    Restore rice without installing packages (requires python3).
  --packages-only  Install packages without restoring configuration.
  --snapshot DIR   Use a different snapshot with home/ and system/ directories.
Run as a regular user with sudo privileges. Package-manager and AUR prompts stay enabled.
HELP
}
while (($#)); do
  case "$1" in
    --dry-run) DRY=1;;
    --config-only) CONFIG_ONLY=1;;
    --packages-only) PACKAGES_ONLY=1;;
    --snapshot) (($#>=2)) || { usage; exit 2; }; SNAPSHOT=$2; shift;;
    -h|--help) usage; exit 0;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2;;
  esac
  shift
done
((CONFIG_ONLY && PACKAGES_ONLY)) && { echo 'Choose only one partial mode.' >&2; exit 2; }
if ((!PACKAGES_ONLY)); then
  [[ -d "$SNAPSHOT/home" && -f "$SNAPSHOT/manifest.json" ]] || { echo 'Invalid snapshot.' >&2; exit 1; }
fi
REPO=(base-devel git curl wget unzip zip rsync python python-psutil zsh eza fzf ripgrep
  openbox obconf-qt sxhkd kitty rofi picom feh wmctrl xdotool xclip maim spectacle
  xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xprop xorg-xrdb
  dbus dunst libnotify slock jq playerctl alsa-utils pavucontrol
  pipewire pipewire-audio pipewire-pulse wireplumber
  xsettingsd polkit polkit-gnome gvfs gvfs-mtp thunar xdg-utils xdg-user-dirs xdg-desktop-portal-gtk
  breeze-gtk breeze-icons breeze-cursors fontconfig ttf-hack ttf-dejavu
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols xorg-fonts-75dpi
  fastfetch polybar bspwm pyenv go code steam qbittorrent)
AUR=(eww opera-gx burpsuite google-chrome)
printf 'Snapshot: %s\nDestination: %s\n' "$SNAPSHOT" "$HOME"
if ((!CONFIG_ONLY)); then
  printf '\nOfficial packages:\n%s\n' "${REPO[*]}"
  printf '\nAUR packages (+ yay if missing):\n%s\n' "${AUR[*]}"
  echo 'Steam requires multilib; pacman.conf will be backed up before enabling it.'
  echo 'A full pacman -Syu upgrade precedes installation (no partial upgrades).'
fi
if ((!PACKAGES_ONLY)); then
  echo 'Restore: dotfiles, desktop configs, scripts, launchers, icons, fonts, wallpapers.'
  echo 'Existing differing files are saved under ~/.local/state/archconfig-backups/.'
  echo 'The custom Openbox theme and saved system fonts are installed in your user directories.'
fi
((DRY)) && { echo 'DRY RUN: no changes made.'; exit 0; }
((EUID!=0)) || { echo 'Run as your regular user, not root/sudo.' >&2; exit 1; }
[[ -f /etc/arch-release ]] || { echo 'This installer targets Arch Linux.' >&2; exit 1; }
if ((!CONFIG_ONLY)); then
  command -v sudo >/dev/null || { echo 'sudo is required.' >&2; exit 1; }
  if ! sudo -n true 2>/dev/null; then
    sudo -v
  fi
  if ! pacman-conf --repo-list | grep -qx multilib; then
    CONF_BACKUP="/etc/pacman.conf.archconfig-$(date +%Y%m%d-%H%M%S)"
    sudo cp -a /etc/pacman.conf "$CONF_BACKUP"
    # Only uncomment the multilib stanza/include; append if it is absent.
    PACMAN_TEMP=$(mktemp -t archconfig-pacman.XXXXXXXX)
    awk '
      /^[[:space:]]*#?[[:space:]]*\[multilib\][[:space:]]*$/ {print "[multilib]"; inside=1; found=1; next}
      inside && /^[[:space:]]*#?[[:space:]]*Include[[:space:]]*=/ {sub(/^[[:space:]]*#[[:space:]]*/, ""); print; inside=0; next}
      /^[[:space:]]*#?[[:space:]]*\[/ {inside=0}
      {print}
      END {if(!found) print "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist"}
    ' /etc/pacman.conf > "$PACMAN_TEMP"
    sudo install -m 644 "$PACMAN_TEMP" /etc/pacman.conf
    rm -f -- "$PACMAN_TEMP"
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
  python3 "$BASE/restore-rice.py" "$SNAPSHOT" "$HOME"
  command -v fc-cache >/dev/null && fc-cache -f "$HOME/.local/share/fonts"
  command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications"
fi
cat <<'DONE'
Finished. Log out and choose Openbox in your existing login manager, or run startx from a TTY.
No login manager, shell change, GPU driver or bootloader configuration was forced.
To choose Zsh as your login shell: chsh -s /usr/bin/zsh
Check the monitor connector/mode in ~/.config/openbox/autostart on different hardware.
Your personal source projects, virtual environments and app credentials are not in this backup.
DONE
