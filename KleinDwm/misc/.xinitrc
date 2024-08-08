#!/bin/sh
# This is a shell script, read by xinit or startx during the start of the X windows system. File configures the behavior and setup of the X session. 

# Start Picom
picom --config ~/.config/picom/picom.conf & 

# Start feh for bg
feh --bg-scale ~/Pictures/backgrounds/jellyfishbg.jpg

# Start xrandr 

# Start Statusbar

# Start First Terminal
(sleep 1 && alacritty -e bash -c "neofetch; lsd; exec bash") &

# Start Custom SystemTrays
# Start SystemTrays (Not-mine)
pkill volumeicon; sleep 1; volumeicon &
pkill copyq; sleep 2; copyq &
# Start monitoring Scripts
exec dwm
