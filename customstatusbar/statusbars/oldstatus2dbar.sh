#!/bin/bash
# This is a relic of the old. Shit sucks


##Global Definitions
#Color definitions
color_black="#000000" #outline
color_white="#ffffff" #default
color_green="#00ff00"
color_yellow="#ffff00"
color_red="#ff0000" 
color_grey="#555555"

#Primary scheme - medium orchid
color_scheme_1="#c067dd" #background 
color_scheme_2="#a656c2" 
color_scheme_3="#8B45A7"
color_scheme_4="#71348C" #highlight
color_scheme_5="#572371"
color_scheme_6="#3C1256" 
color_scheme_7="#22013B" #default text color

#Complimentary scheme - pastel green
c_color_scheme_1="#84dd67" #Complimentary background color
c_color_scheme_2="#72c059"
c_color_scheme_3="#60a44b"
c_color_scheme_4="#4f883d" #Complimentary highlight
c_color_scheme_5="#3f6e30"
c_color_scheme_6="#2f5523"
c_color_scheme_7="#203d17" #Complimentary txt color

#GLobal basics
basic_y=27
basic_x=0

get_cpu() {
    local cpu_stats=$(top -bn1 | rep "%pu(s)")
    local us=$(echo $cpu_stats | awk '{print $2}' | tr -d '%')
    local sy=$(echo $cpu_stats | awk '{print $4}' | tr -d '%')
    local ni=$(echo $cpu_stats | awk '{print $6}' | tr -d '%')
    local id=$(echo $cpu_stats | awk '{print $8}' | tr -d '%')
    local wa=$(echo $cpu_stats | awk '{print $10}' | tr -d '%')
    local hi=$(echo $cpu_stats | awk '{print $12}' | tr -d '%')
    local si=$(echo $cpu_stats | awk '{print $14}' | tr -d '%')
    local st=$(echo $cpu_stats | awk '{print $16}' | tr -d '%')

    local top_cpu_consumer=$(ps -eo %cpu,comm --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $2}')
    top_cpu_consumer="${top_cpu_consumer:0:8}"
    
    local base_x=$basic_x
    local base_y=$basic_y
    local max_height=16
    local bar_width=3
    local status_line=""
    local bg=$color_grey

    declare -A colors=( [us]="#ffd700" [sy]="#ff4500" [ni]="#ff8c00" [id]="#008000"
                        [wa]="#0000ff" [hi]="#4b0082" [si]="#800080" [st]="#a0522d" )

    for state in us sy ni id wa hi si st; do
        local percentage=$(echo ${!state})
        if [[ ! "$percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            percentage=0
        fi

        local bar_height=$(echo "$percentage * $max_height / 100" | bc)
        
        status_line+="^c$bg^^r${base_x},$((base_y - max_height)),${bar_width},${max_height}^"
        
        local upper_y=$((base_y - bar_height))
        status_line+="^c${colors[$state]}^^r$base_x,$upper_y,$bar_width,$bar_height^"
        base_x=$((base_x + bar_width + 2))
    done

    status_line+="^d^^f30^"

    echo "{[$status_line][User:$us|Sys:$sy]$top_cpu_consumer]}"
}

get_ram() {
    local mem_info=$(free -m)
    local total_mem=$(echo "$mem_info" | awk '/^Mem:/ {print $2}')
    local used_mem=$(echo "$mem_info" | awk '/^Mem:/ {print $3}')

    local mem_usage=$(awk "BEGIN {printf \"%.0f\", ($used_mem/$total_mem)*100}")

    local max_height=20
    local bar_height=$((max_height * mem_usage / 100))
    local bar_width=5
    local base_x=$basic_x
    local base_y=$basic_y
    local color=$color_white
    local border=$color_black
    local bg=$color_grey

    local status_line=""
    status_line+="^c$bg^"
    status_line+="^r$base_x,$((base_y - max_height)),$((bar_width + 2)),$((max_height + 2))^"
    status_line+="^c$color^"
    status_line+="^r$((base_x + 1)),$((base_y - bar_height - 1)),${bar_width},${bar_height}^"
    status_line+="^d^^f8^"
    status_line+="${mem_usage}%"

    echo "{[$status_line]}"
}

get_df() {
    # Fetch disk usage data
    local usage_p2=$(df -h | grep '/dev/nvme0n1p2' | awk '{print $5}' | tr -d '%')
    local usage_p4=$(df -h | grep '/dev/nvme0n1p4' | awk '{print $5}' | tr -d '%')
    
    # Safeguard against malformed input
    if [[ ! "$usage_p2" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        usage_p2=0
    fi
    if [[ ! "$usage_p4" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        usage_p4=0
    fi

    # Base settings for drawing
    local base_x=$basic_x
    local base_y=$basic_y
    local max_height=20
    local bar_width=3
    local status_line=""
    local bg=$color_grey

    # Define colors for each partition
    declare -A colors=(
        [p2]="#FFD700"
        [p4]="#FF4500"
    )

    # Define percentages
    local -A usages=(
        [p2]=$usage_p2
        [p4]=$usage_p4
    )

    # Create a vertical bar for each partition
    for partition in p2 p4; do
        local percentage=${usages[$partition]}
        local bar_height=$(echo "$percentage * $max_height / 100" | bc)

        # Draw the background rectangle for 100% capacity
        status_line+="^c$bg^^r${base_x},$((base_y - max_height)),${bar_width},${max_height}^"

        # Draw the usage bar on top of the background
        local upper_y=$((base_y - bar_height))
        status_line+="^c${colors[$partition]}^^r$base_x,$upper_y,$bar_width,$bar_height^"
        base_x=$((base_x + bar_width + 2))
    done

    # Reset formatting and move forward
    status_line+="^d^^f10^"

    echo "{[$status_line][Sys:$usage_p2%|User:$usage_p4%]}"
}

get_temperature() {
    local temp=$(sensors | awk '/Package id 0/ {gsub(/[^0-9.]/, "", $4); print int($4)}')
    local max_temp=70

    local color=$color_white
    local bg=$color_scheme_1
    local outline=$color_white

    if [ "$temp" -gt "$max_temp" ]; then
        color=$color_red
    elif [ "$temp" -lt "$max_temp" ]; then
        color=$color_green
    fi

    local fill_height=$(($temp * 10 / $max_temp))
    local base_y=$((basic_y - 22))
    local temp_icon="^c$outline^"
    temp_icon+="^r5,$base_y,4,11^"
    temp_icon+="^c$bg^"
    temp_icon+="^r6,$((base_y + 4)),2,9^"
    temp_icon+="^c$color^"
    temp_icon+="^r6,$((base_y + 7 - fill_height)),2,$fill_height^"
    temp_icon+="^c$outline^"
    temp_icon+="^r4,$((base_y + 8)),7,4^"
    temp_icon+="^r5,$((base_y + 9)),5,4^"
    temp_icon+="^d^^f10^"
    echo "^c$color_white^{[^d^$temp_icon $temp°C^c$color_white^]}^d^"
}

get_battery() {
    local status=$(cat /sys/class/power_supply/BAT0/status)
    local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
    local current_now=$(cat /sys/class/power_supply/BAT0/current_now)
    local voltage_now=$(cat /sys/class/power_supply/BAT0/voltage_now)
    local power_consumption=$(awk "BEGIN {printf \"%.2f\n\", ($current_now/1000000)*($voltage_now/1000000)}")

    local color=$color_scheme_7
    local bg=$color_scheme_1
    local outline=$color_black
    local color_status=$color_white
    
    if [[ "$capacity" -le 15 ]]; then
        color=$color_red
        shutdown -h now
    elif [[ "$capacity" -le 25 ]]; then
        color=$color_yellow
    else
        color=$color_green
    fi

    local fill_width=$(($capacity * 20 / 100))
    local base_y=$((basic_y - 20))
    local battery_icon="^c$outline^"
    battery_icon+="^r2,$base_y,22,10^"
    battery_icon+="^c$bg^"
    battery_icon+="^r3,$((base_y +1)),20,8^"
    battery_icon+="^c$color^"
    battery_icon+="^r3,$((base_y + 1)),$fill_width,8^"
    battery_icon+="^c$outline^"
    battery_icon+="^r0,$((base_y + 3)),2,4^"
    battery_icon+="^d^^f24^"

    if [[ "$status" == "Full" ]]; then
        status="F"
        color_status=$color_green
    elif [[ "$status" == "Charging" ]]; then
        status="C"
        color_status=$c_color_scheme_1
    elif [[ "$status" == "Discharging" ]]; then
        status="D"
        color_status=$color_yellow
    elif [[ "$status" == "Not charging" ]]; then
        status="NC"
        color_status=$color_scheme_4
    else
        status="NA"
    fi

    echo "{[$battery_icon^c$color^$capacity^d^%]}"
}

get_wifi() {
    local color=$color_black
    local bg=$color_grey
    local ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
    ssid="${ssid:-No WiFi}"
    ssid="${ssid:0:15}"

    local dwm=$(grep wlp0s20f3 /proc/net/wireless | awk '{ print int($4) }')
    local signal_normalized=$(( (dwm + 90) * 100 / 60 ))
    local signal
    if [ $signal_normalized -gt 100 ]; then
        signal=100
    elif [ $signal_normalized -lt 0 ]; then
        signal=0
    else
        signal=$signal_normalized
    fi

    local color=$color_white
    if [ $signal -ge 66 ]; then
        color=$color_green
    elif [ $signal -le 33 ]; then
        color=$color_red
    elif [ $signal -gt 33 ] && [ $signal -lt 66 ]; then
        color=$color_yellow
    fi

    local base_x=$basic_x
    local base_y=$((basic_y - 7))
    local max_bars=5
    local bars_filled=$((signal / 20))

    local wifi_icon="^c$color^"
    for i in 1 2 3 4 5; do
        local width=$((3 * i + 1))
        local height=$((3 * i + 1))
        local height_placement=$((base_y - height))
        if [ $i -le $bars_filled ]; then
            wifi_icon+="^c$color^"
        else
            wifi_icon+="^c$bg^"
        fi
        wifi_icon+="^r$((base_x + 3 * (i - 1))),$height_placement,$width,$height^"
    done
    wifi_icon+="^d^^f18^"

    echo "{[$wifi_icon$ssid[$signal%]]}"
}

get_screen_width() {
    local screen_width_px=$(xdpyinfo | awk '/dimensions:/ {print $2}' | cut -dx -f1)
    echo $((screen_width_px / 1))
}

get_status() {
    local screen_width=$(get_screen_width)
    declare -A components=(
        [cpu]="$(get_cpu)"
        [ram]="$(get_ram)"
        [df]="$(get_df)"
        [temperature]="$(get_temperature)"
        [battery]="$(get_battery)"
        [wifi]="$(get_wifi)"
    )
    local status_line=""
    local separator=""
    local total_length=0
    local sep_length=${#separator}

    for component in date wifi battery temperature df ram cpu; do
        local component_output="${components[$component]}"
        local component_length=$(( ${#component_output} + sep_length ))

        if [[ $((total_length + component_length)) -le $screen_width ]]; then
            status_line="${component_output}${status_line}"
            total_length=$((total_length + component_length))
        else
            echo "Skipped: $component due to space constraints"
        fi
    done

    echo "$status_line"
}

while true; do
    xsetroot -name "$(get_status)"
    sleep 1
done
