# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#PS1='[\u@\h \W]\$ '
PS1="\W > \[$(tput sgr0)\]"
#PS1="ようこそ "

shopt -s autocd
bind 'set completion-ignore-case on'

alias \
        ls='ls -hN --color=auto --group-directories-first' \
        cp='cp -iv' \
	mv='mv -iv' \
	rm='rm -vI' \
	mkdir='mkdir -pv' 

alias q='exit'
#alias vim='TERM=xterm-256color vim'
alias n='nnn -xeC'
alias bashrc='vim ~/.bashrc && source ~/.bashrc'
alias server='TERM=xterm-256color ssh server'

export PATH=$PATH:$HOME/.local/bin
#export SVDIR=$HOME/.local/sv
#export XBPS_DISTDIR=$HOME/Git/void-packages/
#export SSH_AUTH_SOCK=$HOME/.ssh/ssh-agent.sock

export EDITOR='vim'
export TERMINAL='foot'

export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1
export ANKI_WAYLAND=1
export LIBVA_DRIVER_NAME=iHD

export SSH_AUTH_SOCK=${HOME}/.ssh/agent
if ! pgrep -u ${USER} ssh-agent > /dev/null; then
    rm -f ${SSH_AUTH_SOCK}
fi
if [ ! -S ${SSH_AUTH_SOCK} ]; then
    eval $(ssh-agent -a ${SSH_AUTH_SOCK} 2> /dev/null)
fi

export BEMENU_OPTS='-H 27 --fn "Iosevka Term 11" --nf "#666666" --nb "#000000" --sb "#000000" --sf "#ffffff" --tf "#af9dde" --hf "#ffffff" --af "#666666" --ab "#000000"' 

export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
