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
