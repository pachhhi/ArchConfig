# Arch Config shell prompt and generic desktop helpers.
autoload -Uz colors
colors
setopt prompt_subst

export LS_COLORS='di=38;2;200;61;235'
export PATH="$HOME/.local/bin:$PATH"

fg_lambda='%F{#6baf35}'
fg_text='%F{#d7d7d7}'
fg_secondary='%F{#7c89a0}'
PROMPT="${fg_lambda}λ %f${fg_text}> %f"
RPROMPT="${fg_secondary}%~%f"

alias ls='eza --icons'
alias ll='eza -lah'
alias la='eza -a'
alias tree='eza --tree --icons'
alias reload-openbox='openbox --reconfigure'

# Personal workflow shortcuts. The projects and credentials stay outside this repo.
openlab() {
  local profile="${OPENVPN_PROFILE:-}"
  if [[ -z "$profile" ]]; then
    local -a profiles
    profiles=("$HOME"/conf/*.ovpn(N))
    if (( ${#profiles} != 1 )); then
      print -u2 'Set OPENVPN_PROFILE or keep exactly one .ovpn file in ~/conf.'
      return 1
    fi
    profile="$profiles[1]"
  fi
  [[ -r "$profile" ]] || { print -u2 "VPN profile not readable: $profile"; return 1; }
  sudo openvpn "$profile"
}

alias ip4='curl -4 ifconfig.me'
venv() {
  local activate="${VENV_ACTIVATE:-$HOME/conf/venv/bin/activate}"
  [[ -r "$activate" ]] || { print -u2 "Virtualenv not found: $activate"; return 1; }
  source "$activate"
}
alias ports='ss -tulpn'
alias translate='$HOME/Tools/Traductor/launcher.sh'
alias box='cd "$HOME/BOX/"'
cheatengine() {
  cd /opt/cheat-engine-zh && wine cheatengine-x86_64.exe "$@"
}
lain() {
  local project="$HOME/Lainv2"
  [[ -r "$project/.venv/bin/activate" ]] || { print -u2 "Lainv2 virtualenv not found: $project/.venv"; return 1; }
  source "$project/.venv/bin/activate" && python3 "$project/main.py" "$@"
}
alias bspwmrc='nvim "$HOME/.config/bspwm/bspwmrc"'
alias sxhkdrc='nvim "$HOME/.config/sxhkd/sxhkdrc"'
alias polybarc='nvim "$HOME/.config/polybar/config.ini"'

mkt() { mkdir -p -- data exploit }
pentestgpt() {
  local project="$HOME/Tools/PentestGPT/pentestgpt_agent"
  (cd "$project" && uv run pentestgpt-agent "$@")
}
