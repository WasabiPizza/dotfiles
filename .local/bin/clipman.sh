#!/usr/bin/env bash

# run this in sway as:
# exec wl-paste -t text --watch myclipman

app_id=$( swaymsg -t get_tree | jq -r '.. | select(.type?) | select(.focused==true)|.app_id'  )
if [[ $app_id != "org.keepassxc.KeePassXC" ]]; then
    clipman store --no-persist
fi
