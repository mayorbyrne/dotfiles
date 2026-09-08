export TERM=xterm-256color

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  typeset -gaU path=(
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /usr/local/bin
    $path
  )
else
  # Linux
  typeset -gaU path=(
    /home/linuxbrew/.linuxbrew/bin
    /home/linuxbrew/.linuxbrew/sbin
    $path
  )
fi

# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/Q1524/.zsh/completions:"* ]]; then export FPATH="/Users/Q1524/.zsh/completions:$FPATH"; fi
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
# ZSH_THEME="kevin" # set by `omz`
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

# macOS-specific paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PATH="/usr/local/sbin:/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
fi

source $ZSH/oh-my-zsh.sh

# fnm (Node.js version manager)
if [ -d "$HOME/.local/share/fnm" ]; then
  eval "$($HOME/.local/share/fnm/fnm env --use-on-cd --shell zsh)"
fi
