# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#PS1='[\u@\h \W]\$ '
PS1="\W > \[$(tput sgr0)\]"
#PS1="ようこそ "

shopt -s autocd
bind 'set completion-ignore-case on'

alias \
        vpi='sudo xbps-install' \
        vpr='sudo xbps-remove -R' \
        vpu='sudo xbps-install -Su' \
        vpq='xbps-query -Rs' \
        vpc='sudo xbps-remove -Oo' \
        vpk='sudo vkpurge rm all'

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
alias mu='sudo wg-quick up it-mil-wg-001'
alias md='sudo wg-quick down it-mil-wg-001'

export PATH=$PATH:$HOME/.local/bin
#export SVDIR=$HOME/.local/sv
#export XBPS_DISTDIR=$HOME/Git/void-packages/
#export SSH_AUTH_SOCK=$HOME/.ssh/ssh-agent.sock

export EDITOR='vim'
export TERMINAL='foot'

export SSH_AUTH_SOCK=${HOME}/.ssh/agent
if ! pgrep -u ${USER} ssh-agent > /dev/null; then
    rm -f ${SSH_AUTH_SOCK}
fi
if [ ! -S ${SSH_AUTH_SOCK} ]; then
    eval $(ssh-agent -a ${SSH_AUTH_SOCK} 2> /dev/null)
fi

export CHROME_FLAGS+="--js-flags=--jitless --enable-system-notifications --enable-features=TouchpadOverscrollHistoryNavigation,VaapiVideoDecoder,VaapiVideoEncoder --disable-features=UseChromeOSDirectVideoDecoder"

export BEMENU_OPTS='-H 32 --fn "Iosevka 11" --nf "#666666" --nb "#000000" --sf "#ffffff" --sb "#000000" --tf "#af9dde" --tb "#000000" --hf "#ffffff" --hb "#000000" --af "#666666" --ab "#000000" --fb "#000000"'

export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
