# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/Q1524/.zsh/completions:"* ]]; then export FPATH="/Users/Q1524/.zsh/completions:$FPATH"; fi
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
#ZSH_THEME="kevin" # set by `omz`
plugins=(git)

source $ZSH/oh-my-zsh.sh

alias gs="git status"
alias gfp="git fetch -p"
alias grh="git reset --hard"
alias mux="bash ~/.config/scripts/mux.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion export NVM_DIR="$HOME/.nvm"

export PATH=$HOME/.npm-global/bin:$HOME/Desktop/dart-sdk/bin:$HOME/.config/scripts:$PATH
source ~/git-prompt.sh

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

precmd() {
 __posh_git_ps1 '$fg[green]%~$fg[white]' ' $ '
}
export PATH="/usr/local/sbin:/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Initialize zsh completions (added by deno install script)
autoload -Uz compinit
compinit
. "/Users/$USER/.deno/env"
