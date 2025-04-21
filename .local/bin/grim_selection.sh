#!/bin/bash
notify-send 'Grim' 'Make a selection'
grim -g "$(slurp)" ~/Drive/Stuff/screenshots/scrot-$(date +"%Y-%m-%d-%H-%M-%S").png 
notify-send 'Grim' 'Screenshot saved'
