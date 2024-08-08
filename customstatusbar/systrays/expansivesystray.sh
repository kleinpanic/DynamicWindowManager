#!/usr/bin/env bash

# Icon path
icon_path="/usr/share/icons/Adwaita/16x16/devices/display-symbolic.symbolic.png"

# Persistent loop to handle the system tray icon
while true; do
    yad --notification --image="$icon_path" \
        --command="bash -c 'if pgrep -x conky > /dev/null; then killall conky; else conky & disown; fi'" &

    # Wait for the tray icon to be closed
    wait $!

    # Sleep to ensure it doesn't respawn too quickly if closed
    sleep 2
done

