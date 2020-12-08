#!/bin/bash
notify-send 'Maim' 'Make a selection' --icon='/usr/share/icons/Papirus-Dark/16x16/places/folder-photo.svg'
maim -s ~/Pictures/screenshots/$(date +%s).png | xclip -selection clipboard -t image/png
notify-send 'Maim' 'Screenshot saved' --icon='/usr/share/icons/Papirus-Dark/16x16/places/folder-photo.svg'
