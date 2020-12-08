PROMPT="%K{cyan}%F{black} > %f%k "
RPROMPT="%~"

zstyle ':completion:*' completer _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle :compinstall filename '~/.config/zsh/.zshrc'

HISTFILE=~/.config/zsh/.zsh_history
HISTSIZE=1000
SAVEHIST=10000

autoload -Uz compinit
compinit
setopt COMPLETE_ALIASES

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^P" up-line-or-beginning-search
bindkey "^N" down-line-or-beginning-search

unsetopt beep
bindkey -v

alias \
	ls='nnn -deC' \
	cp='cp -iv' \
	mv='mv -iv' \
	rm='rm -vI' \
	mkdir='mkdir -pv' 

alias gpg='gpg2'	
alias zshrc='nvim ~/.config/zsh/.zshrc && source ~/.config/zsh/.zshrc'
alias ssh='TERM=xterm-256color ssh'
alias vim='nvim'
#alias vim='TERM=xterm-256color vim'
alias n='nnn -xeC'
alias dc='docker-compose'
alias cadrl='docker exec -w /etc/caddy caddy caddy reload'
alias mountred='rclone mount gdrive:/redacted /home/nero/.local/red --allow-other --log-level INFO --poll-interval 15s --vfs-read-chunk-size 32M'
alias umountred='fusermount -u /home/nero/.local/red'

#function ssh () {/usr/bin/ssh -t $@ "tmux attach || tmux new";}
