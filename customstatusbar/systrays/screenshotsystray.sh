#!/bin/bash

# Icon path
icon_path="/usr/share/icons/Adwaita/16x16/devices/camera-photo-symbolic.symbolic.png"

# Directory to save screenshots
screenshot_dir="/home/klein/Pictures/screenshots"
export screenshot_dir  # Export the directory path

# Ensure directory exists
mkdir -p "$screenshot_dir"

# Persistent loop to handle the system tray icon
while true; do
    yad --notification --image="$icon_path" \
        --command="bash -c '\
        while :; do \
            yad --title \"Screenshot Tool\" --width=300 --height=50 \
                --button=\"Full Screen:0\" --button=\"Select Window:1\" --button=\"Cancel:2\" \
                --center; \
            ret=\$?; \
            counter=1; \
            while true; do \
                file_path=\"\$screenshot_dir/Screenshot_\${counter}.png\"; \
                if [[ ! -f \"\$file_path\" ]]; then \
                    break; \
                fi; \
                ((counter++)); \
            done; \
            case \$ret in \
                0) \
                    scrot \"\$file_path\"; \
                    break; ;; \
                1) \
                    scrot -s \"\$file_path\"; \
                    break; ;; \
                2|*) \
                    break; ;; \
            esac; \
        done'" \
    # Sleep to ensure it doesn't respawn too quickly if closed
    sleep 2
done
