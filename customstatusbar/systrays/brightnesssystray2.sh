#!/bin/bash

icon_name="/usr/share/icons/Adwaita/16x16/status/display-brightness-symbolic.symbolic.png"

# Persistent loop to handle the system tray icon
while true
do
    # Command to keep the icon in the systray and open the dialog on click
    yad --notification --image="$icon_name" \
        --command="bash -c '\
        while : ; do \
            current_brightness=\$(brightnessctl get 2>/dev/null); \
            max_brightness=\$(brightnessctl max 2>/dev/null); \
            brightness_percent=\$((current_brightness * 100 / max_brightness)); \
            command_output=\$(yad --title \"Brightness Control\" --width=300 --height=150 --posx=810 --posy=575 \
                --form --separator=\",\" --field=\"Set Brightness (0-100):NUM\" \"\$brightness_percent\"!0..100!1 \
                --scale --value=\$brightness_percent --min-value=0 --max-value=100 --step=1 \
                --button=\"Increase Brightness\":1 --button=\"Decrease Brightness\":2 --button=gtk-ok:0 --button=gtk-cancel:3 \
                --fixed --undecorated --on-top --skip-taskbar --skip-pager 2>/dev/null); \
            ret=\$?; \
            case \$ret in \
                0) \
                    new_brightness=\$(echo \$command_output | cut -d ',' -f 1); \
                    brightnessctl set \$new_brightness% > /dev/null 2>&1; \
                    break;; \
                1) \
                    current_brightness=\$(brightnessctl get 2>/dev/null); \
                    max_brightness=\$(brightnessctl max 2>/dev/null); \
                    brightness_percent=\$((current_brightness * 100 / max_brightness)); \
                    new_brightness=\$((brightness_percent + 10)); \
                    [ \$new_brightness -gt 100 ] && new_brightness=100; \
                    brightnessctl set \$new_brightness% > /dev/null 2>&1; \
                    continue;; \
                2) \
                    current_brightness=\$(brightnessctl get 2>/dev/null); \
                    max_brightness=\$(brightnessctl max 2>/dev/null); \
                    brightness_percent=\$((current_brightness * 100 / max_brightness)); \
                    new_brightness=\$((brightness_percent - 10)); \
                    [ \$new_brightness -lt 0 ] && new_brightness=0; \
                    brightnessctl set \$new_brightness% > /dev/null 2>&1; \
                    continue;; \
                3) \
                    break;; \
                *) \
                    break;; \
            esac; \
        done'"
    
    # Sleep to ensure it doesn't respawn too quickly if closed
    sleep 0.5
done
