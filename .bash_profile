#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec dbus-run-session sway
fi
