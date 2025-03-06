#!/usr/bin/env bash
#
# Please be aware that I only run debian. Idk if this script will work for all 
# Name: dwm-deps-installer.sh
# Purpose: Attempt to install dependencies for dwm (with multiple patches)
#          across a wide range of Operating Systems and distributions.
# Author: ChatGPT (with user’s requirements)
# ---------------------------------------------------------------------

set -Eeuo pipefail

#----------------------------------------------
# Helper Functions
#----------------------------------------------

# Colored echo helpers (optional, remove if you don’t want colors):
RED="$(tput setaf 1 || true)"
GREEN="$(tput setaf 2 || true)"
YELLOW="$(tput setaf 3 || true)"
BLUE="$(tput setaf 4 || true)"
BOLD="$(tput bold || true)"
RESET="$(tput sgr0 || true)"

info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }

# Ensure the user is either root or can use sudo (for distros that require it).
check_root_or_sudo() {
    if (( $EUID == 0 )); then
        info "Running as root."
    else
        # Check if sudo is present
        if ! command -v sudo &>/dev/null; then
            error "You need 'sudo' installed or to run this script as root!"
            exit 1
        fi
    fi
}

#----------------------------------------------
# Detect Operating System
#----------------------------------------------
# Strategy:
# 1. Check `uname -s` for high-level OS detection (e.g., "Linux", "Darwin", "FreeBSD", "OpenBSD", "NetBSD", "SunOS", "CYGWIN_NT-10.0", "MSYS_NT-10.0", etc.).
# 2. If Linux, parse /etc/os-release for distribution ID.
# 3. If *BSD, parse `uname -s` or other known markers.
# 4. If Windows (Cygwin, MSYS, etc.), note that direct DWM usage is limited unless WSL is used.
# 5. If macOS (Darwin), note that you can't replace the system WM. We'll still do a brew-based install for X-related libs.
# 6. If illumos/Solaris (SunOS), attempt typical "pkg" or "pkgutil" usage, but this can vary widely.

detect_os() {
    local unameOut
    unameOut="$(uname -s 2>/dev/null || true)"

    case "${unameOut}" in
        Linux*)   echo "Linux";;
        Darwin*)  echo "macOS";;
        FreeBSD*) echo "FreeBSD";;
        OpenBSD*) echo "OpenBSD";;
        NetBSD*)  echo "NetBSD";;
        DragonFly*) echo "DragonFlyBSD";;
        SunOS*)   echo "SunOS";;  # Could be illumos or Solaris
        CYGWIN*|MINGW*|MSYS*) echo "Windows";;
        *)
          # unknown
          echo "UnknownOS"
          ;;
    esac
}

#----------------------------------------------
# Install function for Linux distributions
#----------------------------------------------
install_deps_linux() {
    # We'll attempt to parse /etc/os-release to get the distribution ID
    local distro="Unknown"
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        distro="${ID:-Unknown}"
        # Some distros (like Pop!_OS) might have ID=ubuntu but ID_LIKE=debian
        # We might also check $ID_LIKE to refine guesses
    fi

    info "Detected distro ID: $distro"
    # Lowercase just in case
    distro="${distro,,}"

    # Basic note: We need dev packages for:
    #   - X11 (libx11, dev headers)
    #   - Xft (libxft, dev)
    #   - Xinerama (libxinerama, dev)
    #   - Yajl (libyajl, dev) for certain patches
    #   - xinit
    #   - xorg/xserver

    case "$distro" in
        # ---------------------------------------------------------------
        # Debian / Ubuntu / Mint / etc. (apt-based)
        # ---------------------------------------------------------------
        debian|ubuntu|linuxmint|pop|neon|elementary|zorin|kali|parrot|\
        raspbian|devuan|galliumos|lite|sparkylinux|peppermint|bunsenlabs|\
        bodhi|pureos|siduction)
            info "Using apt-get/apt to install dependencies..."
            sudo apt-get update
            sudo apt-get install -y \
                libx11-dev libxft-dev libxinerama-dev libyajl-dev \
                xorg xinit
            ;;

        # ---------------------------------------------------------------
        # Arch / Manjaro / Endeavour / Artix / etc. (pacman-based)
        # ---------------------------------------------------------------
        arch|manjaro|endeavouros|arco|artix|garuda)
            info "Using pacman to install dependencies..."
            sudo pacman -Syu --noconfirm --needed \
                xorg-server xorg-xinit libx11 libxft libxinerama yajl
            ;;

        # ---------------------------------------------------------------
        # Fedora (dnf)
        # ---------------------------------------------------------------
        fedora)
            info "Using dnf to install dependencies..."
            sudo dnf install -y \
                libX11-devel libXft-devel libXinerama-devel yajl-devel \
                xorg-x11-server-Xorg xorg-x11-xinit
            ;;

        # ---------------------------------------------------------------
        # RHEL / CentOS / Rocky / Alma (dnf/yum)
        # ---------------------------------------------------------------
        rhel|centos|rocky|alma)
            info "Using dnf (or yum) to install dependencies..."
            sudo dnf install -y \
                libX11-devel libXft-devel libXinerama-devel yajl-devel \
                xorg-x11-server-Xorg xorg-x11-xinit
            ;;

        # ---------------------------------------------------------------
        # openSUSE / SUSE (zypper)
        # ---------------------------------------------------------------
        opensuse*|suse|sle*)
            info "Using zypper to install dependencies..."
            sudo zypper refresh
            sudo zypper install -y \
                libX11-devel libXft-devel libXinerama-devel libyajl-devel \
                xorg-x11-server xinit
            ;;

        # ---------------------------------------------------------------
        # Mageia / OpenMandriva (urpmi or dnf in some versions)
        # ---------------------------------------------------------------
        mageia|openmandriva)
            # Mageia uses urpmi
            if command -v urpmi &>/dev/null; then
                info "Using urpmi to install dependencies..."
                sudo urpmi.update -a
                sudo urpmi --auto \
                    lib64x11-devel lib64xft-devel lib64xinerama-devel lib64yajl-devel \
                    xinit x11-server-xorg
            else
                # Some derivatives might use dnf
                warn "urpmi not found. Trying dnf..."
                sudo dnf install -y \
                    libX11-devel libXft-devel libXinerama-devel yajl-devel \
                    xorg-x11-server-Xorg xorg-x11-xinit
            fi
            ;;

        # ---------------------------------------------------------------
        # PCLinuxOS (apt-rpm? Synaptic? Hard to detect. Possibly uses urpmi.)
        # ---------------------------------------------------------------
        pclinuxos)
            warn "PCLinuxOS uses apt-rpm or Synaptic. Attempting apt-get..."
            sudo apt-get update || true
            sudo apt-get install -y \
                libx11-dev libxft-dev libxinerama-dev libyajl-dev \
                xorg xinit || {
                error "Failed apt-get on PCLinuxOS. Please install manually."
                exit 1
            }
            ;;

        # ---------------------------------------------------------------
        # Slackware (slackpkg)
        # Slackware typically includes dev headers by default, but let's try:
        #   slackpkg update
        #   slackpkg install xorg x11 x11-devel etc. 
        # Slackware doesn’t always break them into separate -dev packages.
        # If you have the Slackware DVD, you may need to install the "X"
        # series and "D" (development) series fully.
        # We'll attempt partial coverage:
        # ---------------------------------------------------------------
        slackware)
            warn "Slackware detection. Attempting 'slackpkg' usage..."
            # We’ll do a best-effort. Might require manual steps:
            sudo slackpkg update || true
            # There might not be exact package naming for dev libs.
            warn "Please ensure X, x11 dev, xinerama dev, xft dev, and yajl dev are installed from Slackware's 'X' and 'D' series. Attempting partial installation..."
            # Slackpkg might not have granularity for these. We'll try:
            sudo slackpkg install x11 xorg || true
            # Yajl might be in SlackBuilds or might already be included.
            success "Slackware can be tricky. Check your installed packages or SlackBuild for Yajl if needed."
            ;;

        # ---------------------------------------------------------------
        # Gentoo / Funtoo / Sabayon / Calculate (emerge or equo for Sabayon)
        # ---------------------------------------------------------------
        gentoo|funtoo)
            info "Using emerge for Gentoo/Funtoo..."
            sudo emerge --sync
            # On Gentoo, you might set USE flags. We'll do a minimal approach:
            # The relevant packages might be x11-libs/libX11, x11-libs/libXft,
            # x11-libs/libXinerama, dev-libs/yajl, x11-base/xorg-server, x11-apps/xinit
            sudo emerge -n \
                x11-libs/libX11 x11-libs/libXft x11-libs/libXinerama dev-libs/yajl \
                x11-base/xorg-server x11-apps/xinit
            ;;

        sabayon)
            info "Sabayon (now part of MocaccinoOS?), using 'equo' or 'emerge'..."
            if command -v equo &>/dev/null; then
                sudo equo update
                sudo equo install \
                    x11-libs/libX11 x11-libs/libXft x11-libs/libXinerama dev-libs/yajl \
                    xorg-server xinit
            else
                warn "No 'equo'. Trying emerge..."
                sudo emerge -n \
                    x11-libs/libX11 x11-libs/libXft x11-libs/libXinerama dev-libs/yajl \
                    x11-base/xorg-server x11-apps/xinit
            fi
            ;;

        # ---------------------------------------------------------------
        # Void (xbps)
        # ---------------------------------------------------------------
        void)
            info "Using xbps-install for Void..."
            sudo xbps-install -S
            sudo xbps-install -y \
                libX11-devel libXft-devel libXinerama-devel yajl-devel \
                xorg xorg-server xinit
            ;;

        # ---------------------------------------------------------------
        # Alpine (apk)
        # ---------------------------------------------------------------
        alpine)
            info "Using apk for Alpine..."
            sudo apk update
            sudo apk add \
                libx11-dev libxft-dev libxinerama-dev yajl-dev \
                xorg-server xinit
            ;;

        # ---------------------------------------------------------------
        # NixOS
        # On NixOS, you generally manage environment/system packages in
        # configuration.nix or use `nix-env -iA`.
        # ---------------------------------------------------------------
        nixos)
            warn "NixOS detected. Attempting 'nix-env -iA nixpkgs.packageName'..."
            warn "You may want to manage this in /etc/nixos/configuration.nix."
            nix-env -iA nixpkgs.libX11 nixpkgs.libXft nixpkgs.libXinerama nixpkgs.yajl nixpkgs.xorg.xorgserver nixpkgs.xorg.xinit
            ;;

        # ---------------------------------------------------------------
        # Clear Linux (swupd)
        # ---------------------------------------------------------------
        clear-linux*|clearlinux)
            info "Clear Linux detected. Using swupd..."
            sudo swupd update
            sudo swupd bundle-add \
                x11-tools os-core-dev C-basic libsdl devpkg-yajl # best guess
            warn "Ensure xorg-server and xinit equivalents are installed in Clear Linux (bundles)."
            ;;

        # ---------------------------------------------------------------
        # Solus (eopkg)
        # ---------------------------------------------------------------
        solus)
            info "Solus detected. Using eopkg..."
            sudo eopkg update-repo
            sudo eopkg install -y \
                libx11-devel libxft-devel libxinerama-devel yajl-devel \
                xorg-server xorg-xinit
            ;;

        # ---------------------------------------------------------------
        # If we get here, we don't have a recognized distro or ID is missing
        # We'll attempt a generic approach or just print instructions.
        # ---------------------------------------------------------------
        *)
            error "Unrecognized or unsupported Linux distro: '$distro'"
            echo
            echo "Please manually install the following packages for your distro's package manager:"
            echo "  * X11 development libraries (libX11, dev headers)"
            echo "  * Xft (libXft) with dev headers"
            echo "  * Xinerama (libXinerama) with dev headers"
            echo "  * Yajl (libyajl) with dev headers"
            echo "  * xorg-server / xinit"
            echo "Then you can compile dwm."
            exit 1
            ;;
    esac

    success "Dependency installation complete for distro: $distro"
}

#----------------------------------------------
# Install function for BSD
#----------------------------------------------
install_deps_bsd() {
    local bsdName="$1"
    info "Detected $bsdName..."

    case "$bsdName" in
        FreeBSD)
            # FreeBSD typically uses pkg
            sudo pkg update
            sudo pkg install -y \
                libX11 libXft libXinerama yajl xorg xorg-server xinit
            ;;
        OpenBSD)
            # OpenBSD uses pkg_add. Checking package names can be tricky,
            # they might be named slightly differently, e.g., "xbase" might
            # be part of the OS sets. We'll do a best effort here:
            # Usually X is part of base for OpenBSD. We'll just do the libs:
            # Some packages might be named e.g. `xenocara-libX11`, etc. This is approximate.
            sudo pkg_add xbase xfont xserv # might already be installed
            sudo pkg_add xorg # might include many components
            # For dev libraries:
            sudo pkg_add x11 x11-fmw xft # approximate
            # Yajl is often just "yajl"
            sudo pkg_add yajl
            ;;
        NetBSD)
            # NetBSD might use pkgin or pkg_add from pkgsrc
            if command -v pkgin &>/dev/null; then
                sudo pkgin update
                sudo pkgin -y install libX11 libXft libXinerama yajl xorg
            else
                # fallback to pkg_add
                warn "pkgin not found, trying pkg_add for NetBSD..."
                # Typically you set PKG_PATH, etc. This is a best guess
                sudo pkg_add libX11 libXft libXinerama yajl xorg
            fi
            ;;
        DragonFlyBSD)
            # DragonFly also uses pkg (like FreeBSD). 
            # Some packages might differ in naming:
            sudo pkg update
            sudo pkg install -y \
                xorg libX11 libXft libXinerama yajl
            ;;
        *)
            warn "Generic BSD fallback: Please install X11 dev, Xft dev, Xinerama dev, Yajl dev, xinit, xserver from your BSD's packages/ports."
            ;;
    esac

    success "Finished (attempted) dependency installation on $bsdName."
}

#----------------------------------------------
# Install function for macOS
#----------------------------------------------
install_deps_macos() {
    info "Detected macOS (Darwin)."

    # You cannot truly replace the macOS window manager with dwm.
    # You *can* compile it and run it under an X server (e.g. XQuartz).
    # So we’ll attempt to install the relevant libraries via Homebrew.

    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed. Please install Homebrew from https://brew.sh."
        exit 1
    fi

    # Install XQuartz from cask (optional), plus libs
    brew update
    brew install pkg-config xorg libx11 libxft libxinerama yajl

    # For an X server, often you can do:
    brew install --cask xquartz

    success "macOS libs installed via Homebrew. Remember: you can’t fully replace the macOS WM with dwm!"
}

#----------------------------------------------
# Install function for SunOS / Solaris / illumos
#----------------------------------------------
install_deps_sunos() {
    info "Detected SunOS (Solaris/illumos)."
    # This can vary widely. Some illumos-based distros use "pkg" (OpenIndiana),
    # some use "pkgin" (SmartOS), some use "pkgutil" (OpenCSW on Solaris),
    # or "apt-like" commands in certain forks.

    # We'll guess for OpenIndiana (pkg):
    # "pfexec" is typically used in place of sudo for Solaris derivatives.
    # This is extremely approximate:

    if command -v pfexec &>/dev/null; then
        # Attempt OpenIndiana approach:
        pfexec pkg refresh
        pfexec pkg install x11/header x11/library/libx11 x11/library/libxft \
            x11/library/libxinerama library/yajl \
            x11/server/xorg x11/session/xinit
    else
        # fallback approach
        warn "No pfexec found. Trying 'sudo pkg' or 'sudo pkgutil'."
        if command -v pkg &>/dev/null; then
            sudo pkg refresh || true
            sudo pkg install x11/header x11/library/libx11 x11/library/libxft \
                x11/library/libxinerama library/yajl \
                x11/server/xorg x11/session/xinit || {
                error "Solaris/illumos install attempt failed. Install these packages manually."
            }
        elif command -v pkgutil &>/dev/null; then
            # Possibly using OpenCSW on Solaris
            sudo pkgutil -U
            sudo pkgutil -i \
                libx11_dev libxft_dev libxinerama_dev yajl_dev xorg xinit || {
                error "Could not install via pkgutil. Please do it manually."
            }
        else
            error "No recognized pkg tool on Solaris/illumos. Please install manually."
            exit 1
        fi
    fi

    success "Finished attempted install on SunOS/illumos. This might require manual verification."
}

#----------------------------------------------
# Windows approach
#----------------------------------------------
install_deps_windows() {
    info "Detected Windows environment (Cygwin/Mingw/MSYS)."
    # You cannot replace the Windows manager with dwm. You can compile and run it
    # in an X server environment (like VcXsrv or Xming or MobaXterm).
    #
    # Option 1: WSL (Windows Subsystem for Linux):
    #    If running in WSL, you’re effectively on a Linux environment, so you'd want
    #    to detect that as "Linux" (some older WSL might say "Microsoft" in /etc/os-release).
    #    In that case, the user can do the standard Linux approach above.
    #
    # Option 2: MSYS2 / Cygwin with X packages:
    #    For MSYS2: pacman -S xorg-server xorg-xinit xorgproto libX11-devel ...
    #    For Cygwin: setup-x86_64.exe or "apt-cyg" might be used
    #
    # We'll attempt a best guess for MSYS2 (since it also uses pacman).
    # If it fails, we instruct manual steps.

    if command -v pacman &>/dev/null; then
        # Probably MSYS2
        info "MSYS2 environment detected. Using pacman for MSYS2..."
        pacman -Syu --noconfirm --needed \
            mingw-w64-x86_64-xorgproto mingw-w64-x86_64-libx11 \
            mingw-w64-x86_64-libxft mingw-w64-x86_64-libxinerama \
            mingw-w64-x86_64-yajl
        success "MSYS2 pacman approach done. You still need to run an X server separately."
    else
        warn "No MSYS2 pacman found. Possibly Cygwin or something else. Please install X11 dev libs, X server, X init, Yajl manually using Cygwin setup or chocolatey, etc."
        warn "You CANNOT replace the Windows shell with dwm, only run it under an X server."
    fi
}

#----------------------------------------------
# Main script logic
#----------------------------------------------

main() {
    check_root_or_sudo

    local OS
    OS="$(detect_os)"

    info "Operating System detected as: $OS"

    case "$OS" in
        Linux)
            install_deps_linux
            ;;
        FreeBSD|OpenBSD|NetBSD|DragonFlyBSD)
            install_deps_bsd "$OS"
            ;;
        macOS)
            install_deps_macos
            ;;
        SunOS)
            install_deps_sunos
            ;;
        Windows)
            install_deps_windows
            ;;
        *)
            error "Unsupported or unknown OS: $OS"
            echo "If you’re on an unsupported Linux distro, you can manually install these packages:"
            echo "  libx11-dev, libxft-dev, libxinerama-dev, libyajl-dev, xserver, xinit"
            echo "If you’re on another BSD or obscure system, install the equivalents from your package manager."
            exit 1
            ;;
    esac

    success "Script completed successfully!"
    echo "You should now have the libraries required to build dwm with your patches (where possible)."
    echo
}

main "$@"

