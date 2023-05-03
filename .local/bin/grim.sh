#!/bin/bash
grim ~/Nextcloud/Stuff/screenshots/scrot-$(date +"%Y-%m-%d-%H-%M-%S").png 
notify-send 'Grim' 'Screenshot saved'
