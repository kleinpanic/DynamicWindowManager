#!/usr/bin/env bash

#Check if command exits
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#DWM dependency is running
#if ! pgrep -x "dwm" > /dev/null; then
#    echo "DWM is not running. Please ensure that you got that shit installed and its your window manager."
#    exit 1
#fi

#status2d dependency (update later if you find out how)
if command_exists dwm; then
    echo "DWM is installed. Make sure you got status2D patch applied for properrendering."
fi 

#Package dependcies
requires_packages=("grep" "gawk" "procps" "coreutils" "lm-sensors" "network-manager" "x11-xserver-utils")

for pkg in "${requires_packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Package $pkg is not installed. Installing..."
        sudo apt update
        sudo apt install -y "$pkg"
        if [ $? -ne 0 ]; then
            echo "Failed to install $pkg. Install it manually, or its equivalent and edit source code"
            exit 1
        fi
    else 
        echo "Package $pkg is installed already. YAY"
    fi 
done 
sudo chmod +x statusbar.sh
sudo cp statusbar.sh /usr/local/bin/statusbar

PREFIX="$HOME/.local/share/statusbar"
mkdir -p "$PREFIX"
cp colorvars.sh "$PREFIX"

echo "Installation done. Run statusbar in shell. Installed to local bin"
