#!/usr/bin/env bash

# Source color vars
source "$HOME/.local/share/statusbar/colorvars.sh"

# Define Basic Dimentions
base_x=0
base_y=2
max_height=23
bar_width=5
gap=5

clock() {
    # Adjusted dimensions for the clock icon
    local icon_width=18
    local icon_height=$((max_height - 2))
    
    # Determine the center of the icon (for the dial)
    local center_x=$((base_x + icon_width / 2))
    local center_y=$(((base_y + 2) + icon_height / 2))

    # Begin drawing the clock icon.
    # Outer border (clock frame) in medium gray.
    local clock_icon=""
    clock_icon+="^c${grey}^"
    clock_icon+="^r${base_x},$((base_y + 2)),${icon_width},${icon_height}^"
    # Inner dial (face), inset by 3 pixels on all sides.
    clock_icon+="^c#000000^"
    clock_icon+="^r$((base_x + 3)),$((base_y + 5)),$((icon_width - 6)),$((icon_height - 6))^"
    
    # Get current time details.
    local hour=$(date +%H)
    local minute=$(date +%M)
    hour=$((10#$hour))
    minute=$((10#$minute))
    
    # Calculate angles in radians.
    # Hour hand: each hour is 30° plus half a degree per minute.
    local hour_angle
    hour_angle=$(awk -v h="$hour" -v m="$minute" 'BEGIN {
    printf "%.2f", ((-((h % 12) * 30 + m * 0.5) + 90) * 3.14159265 / 180)
    }')
    # Minute hand: each minute represents 6°.
    local minute_angle
    minute_angle=$(awk -v m="$minute" 'BEGIN {
    printf "%.2f", ((-(m * 6) + 90) * 3.14159265 / 180)
    }')

    # Define inner radius from inner dial (the dial drawn is (icon_width-6) wide).
    local inner_radius=$(( (icon_width - 6) / 2 ))
    # Define hand lengths as fractions of the inner radius.
    local hour_hand_length
    hour_hand_length=$(awk -v r="$inner_radius" 'BEGIN { printf "%d", r * 0.6 }')
    local minute_hand_length
    minute_hand_length=$(awk -v r="$inner_radius" 'BEGIN { printf "%d", r * 0.9 }')

    # Function to draw a hand from the center to a given length with specified angle and color.
    # It draws a series of 1x1 pixel rectangles along the hand's path.
    draw_hand() {
        local length=$1
        local angle=$2
        local color=$3
        local hand_line=""
        for (( i=0; i<=length; i++ )); do
            # Compute x and y offset using AWK's cosine and sine functions.
            local dx
            dx=$(awk -v i="$i" -v a="$angle" 'BEGIN { printf "%d", i * cos(a) }')
            local dy
            dy=$(awk -v i="$i" -v a="$angle" 'BEGIN { printf "%d", i * sin(a) }')
            # Note: subtract dy because screen y coordinates increase downward.
            local px=$(( center_x + dx ))
            local py=$(( center_y - dy ))
            hand_line+="^c${color}^"
            hand_line+="^r${px},${py},1,1^"
        done
        echo -n "${hand_line}"
    }

    # Draw the hour hand (white) and the minute hand (light gray).
    local hour_line
    hour_line=$(draw_hand "$hour_hand_length" "$hour_angle" "#FFFFFF")
    local minute_line
    minute_line=$(draw_hand "$minute_hand_length" "$minute_angle" "#AAAAAA")

    # Append the hand drawings to the clock icon.
    clock_icon+="${hour_line}${minute_line}"
    
    # Decrease the gap between the icon and the time text by forwarding the drawing cursor by a smaller amount.
    # Here, we move the cursor by icon_width + gap - 2 pixels.
    clock_icon+="^d^^f$(( icon_width + gap - 2 ))^"
    
    # Fetch the current time (military format HH:MM) with no background.
    local time_str
    time_str=$(date +%H:%M:%S)
    local time_text="${time_str} ^d^"
    
    # Output the complete clock icon and time text without any label.
    echo "${clock_icon}${time_text}"
}

cpu() {
    local cpu_line1=$(grep '^cpu ' /proc/stat)
    sleep 2
    local cpu_line2=$(grep '^cpu ' /proc/stat)
    local -a cpu1=(${cpu_line1//cpu/})
    local -a cpu2=(${cpu_line2//cpu/})
    local total1=0
    local total2=0
    local idle1=${cpu1[3]}
    local idle2=${cpu2[3]}
    for i in "${cpu1[@]}"; do
        total1=$((total1 + i))
    done
    for i in "${cpu2[@]}"; do
        total2=$((total2 + i))
    done
    local total_delta=$((total2 - total1))
    local idle_delta=$((idle2 - idle1))

    local usage=$((100 * (total_delta - idle_delta) / total_delta))

    local usage_height=$(( (max_height * usage) / 100 ))
    local usage_y=$((base_y + max_height - usage_height))
    local color=$white
    if [ $usage -gt 50 ]; then
        color=$red
    fi
    local status_line=""
    status_line+="^c${grey}^^r${base_x},${base_y},${bar_width},${max_height}^"
    status_line+="^c${color}^^r${base_x},${usage_y},${bar_width},${usage_height}^"
    status_line+="^d^^f7^"
    local topcon=$( ps -eo %cpu,comm --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $2}')
	topcon="${topcon:0:5}" # trunkate output
    echo "{CPU:${status_line}${usage}% : ${topcon}}"
}

ram() {
    local m_mem=$(free -m)
    local t_mem=$(echo "$m_mem" | awk '/^Mem:/ {print $2}')
    local u_mem=$(echo "$m_mem" | awk '/^Mem:/ {print $3}')
    local p_mem=$(awk "BEGIN {printf \"%.0f\", ($u_mem/$t_mem)*100}")
    local usage_height=$((max_height * p_mem / 100))
    local usage_y=$((base_y + max_height - usage_height))
    local status_line=""
    status_line+="^c$grey^^r$base_x,${base_y},${bar_width},${max_height}^"
    status_line+="^c$white^^r${base_x},${usage_y},${bar_width},${usage_height}^"
    status_line+="^d^^f7^"
    status_line+="${p_mem}%"
    echo "{Mem:$status_line}"
}

swap() {
    local m_swap=$(free -m)
    local t_swap=$(echo "$m_swap" | awk '/^Swap:/ {print $2}')
    local u_swap=$(echo "$m_swap" | awk '/^Swap:/ {print $3}')
    if [[ "$u_swap" -eq 0 ]]; then
        return
    fi
    local p_swap=$(awk "BEGIN {printf \"%.0f\", ($u_swap/$t_swap)*100}")
    local usage_height=$((max_height * p_swap / 100))
    local usage_y=$((base_y + max_height - usage_height))
    local status_line=""
    status_line+="^c$grey^^r$base_x,${base_y},${bar_width},${max_height}^"
    status_line+="^c$white^^r${base_x},${usage_y},${bar_width},${usage_height}^"
    status_line+="^d^^f7^"
    status_line+="${p_swap}%"
    echo "{Swap:$status_line}|"
}

disk() {
    local usage_p2=$(df -h | grep '/dev/nvme0n1p2' | awk '{print $5}' | tr -d '%')
    local usage_p4=$(df -h | grep '/dev/nvme0n1p4' | awk '{print $5}' | tr -d '%')
    if [[ ! "$usage_p2" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        usage_p2=0
    fi
    if [[ ! "$usage_p4" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        usage_p4=0
    fi
    local status_line=""
    local -A usages=(
        [p2]=$usage_p2
        [p4]=$usage_p4
    )
    for partition in p2 p4; do
        local percentage=${usages[$partition]}
        local usage_height=$(($percentage * $max_height / 100))
        local usage_y=$((base_y + max_height - usage_height))
        status_line+="^c$grey^^r${base_x},${base_y},${bar_width},${max_height}^"
        status_line+="^c$white^^r${base_x},${usage_y},${bar_width},${usage_height}^"
        base_x=$((base_x + bar_width +2))
    done
    status_line+="^d^^f15^"
    echo "{Disk:${status_line}R:${usage_p2}%|U:${usage_p4}%}"
}

cpu_temperature(){
    local temp=$(sensors | awk '/Package id 0/ {gsub(/[^0-9.]/, "", $4); print int($4)}')
    local max_temp=70
    local color=$white
    if [ "$temp" -gt "$max_temp" ]; then
        color=$red
    elif [ "$temp" -lt "$max_temp" ]; then
        color=$green
    fi
    local adj_y=5
    local usage_height=$(($temp * 10 / $max_temp))
    local usage_y=$((adj_y + 10 - usage_height))
    local temp_icon="^c$black^"
    temp_icon+="^r7,${base_y},5,15^" #Bar behind the fill
    temp_icon+="^c$color^"
    temp_icon+="^r8,${usage_y},3,${usage_height}^" # Fill Bar 
    temp_icon+="^c$black^"
    temp_icon+="^r4,17,11,5^" 
    temp_icon+="^r5,19,9,6^"
    temp_icon+="^d^^f15^"
    echo "^c$white^{^d^$temp_icon $temp°C^c$white^}^d^"
}

battery() {
    local status=$(cat /sys/class/power_supply/BAT0/status)
    local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
    local color=$white    
    if [[ "$capacity" -le 15 ]]; then
        color=$red
    elif [[ "$capacity" -le 25 ]]; then
        color=$yellow
    else
        color=$green
    fi 
    local adj_y=7
    local fill_width=$(($capacity * 20 / 100))
    local battery_icon="^c$white^"
    battery_icon+="^r2,10,24,12^"
    battery_icon+="^c$grey^"
    battery_icon+="^r4,12,20,8^"
    battery_icon+="^c$color^"
    battery_icon+="^r4,12,$fill_width,8^"
    battery_icon+="^c$white^"
    battery_icon+="^r26,13,4,6^"
    battery_icon+="^d^^f35^"
    local color_status=$white
    if [[ "$status" == "Full" ]]; then
        color_status=$green
    elif [[ "$status" == "Charging" ]]; then
        color_status=$green
    elif [[ "$status" == "Discharging" ]]; then
        color_status=$grey
    elif [[ "$status" == "Not charging" ]]; then
        color_status=$white
    else
        status="NA"
    fi
    local volt=$(sensors | awk '/BAT0-acpi-0/ {getline; getline; print $2}')
    echo "{${battery_icon}^c${color_status}^${capacity}^d^% ${volt}V}"
}

wifi() {
    local iface=$(ip -o link show | grep -v "lo:" | awk -F': ' '{print $2}')
    local ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
    ssid="${ssid:-No WiFi}"
    ssid="${ssid:0:15}"
    local dwm=$(grep "$iface" /proc/net/wireless | awk '{ print int($4) }')
    if [ "$ssid" = "No WiFi" ]; then
        local signal=0
    else 
        local signal_normalized=$(( (dwm + 90) * 100 / 60 ))
        if [ $signal_normalized -gt 100 ]; then
            signal=100
        elif [ $signal_normalized -lt 0 ]; then
            signal=0
        else
            signal=$signal_normalized
        fi
    fi

    local color=$white
    if [ $signal -ge 66 ]; then
        color=$green
    elif [ $signal -le 33 ]; then
        color=$red
    elif [ $signal -gt 33 ] && [ $signal -lt 66 ]; then
        color=$yellow
    fi

    local max_bars=5
    local bars_filled=$((signal / 20))

    local wifi_icon="^c$color^"
    for i in 1 2 3 4 5; do
        local width=$((3 * i + 1))
        local height=$((3 * i + 1))
        local adj_y=$((max_height - height))
        if [ $i -le $bars_filled ]; then
            wifi_icon+="^c$color^"
        else
            wifi_icon+="^c$grey^"
        fi
        wifi_icon+="^r$((base_x + 4 * (i - 2))),$adj_y,$width,$height^"
    done
    wifi_icon+="^d^^f17^"

    echo "{ $wifi_icon$ssid : $signal% }"
}

status(){
    echo "$(clock)|$(cpu)|$(ram)|$(swap)$(disk)|$(cpu_temperature)|$(battery)|$(wifi)"
}
while true; do
    xsetroot -name "$(status)"
done
