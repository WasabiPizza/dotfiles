#!/bin/bash
grim ~/Pictures/screenshots/scrot-$(date +"%Y-%m-%d-%H-%M-%S").png 
notify-send 'Grim' 'Screenshot saved' --icon='/usr/share/icons/Papirus-Dark/16x16/places/folder-photo.svg'
