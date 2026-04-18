# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/Q1524/.zsh/completions:"* ]]; then export FPATH="/Users/Q1524/.zsh/completions:$FPATH"; fi

plugins=(git)

alias gs="git status"
alias gfp="git fetch -p"
alias grh="git reset --hard"
alias mux="bash ~/.config/scripts/mux.sh"

export PATH=$HOME/.npm-global/bin:$HOME/Desktop/dart-sdk/bin:$HOME/.config/scripts:$PATH
source ~/git-prompt.sh

setopt PROMPT_SUBST
unset zle_bracketed_paste
precmd() {
  __posh_git_ps1 '%F{green}%~%f' ' %# ' ' %F{cyan}' '%f'
}

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Fast prompt with full git status (use starship)
# eval "$(starship init zsh)"

export PATH="$PATH":"$HOME/.pub-cache/bin"

eval "$(fnm env --use-on-cd --shell zsh)"

bindkey '\e[A' history-beginning-search-backward
bindkey '\e[B' history-beginning-search-forward

# Initialize completion
autoload -U compinit; compinit
