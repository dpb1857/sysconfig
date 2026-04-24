#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------------------------
# Actions — add a function here and a matching entry in MENU_ITEMS/MENU_FNS
# ---------------------------------------------------------------------------

action_setup_home() {
    local partlabel_path="/dev/disk/by-partlabel/home"

    if [[ ! -e "$partlabel_path" ]]; then
        echo "No partition named 'home' was found."
        return 0
    fi

    local device fstype uuid
    device=$(readlink -f "$partlabel_path")
    fstype=$(lsblk -no FSTYPE "$device")
    uuid=$(lsblk -no UUID "$device")

    echo "Found partition: $device (type: $fstype, UUID: $uuid)"

    if [[ "$fstype" == "btrfs" ]]; then
        echo "Partition is btrfs — installing btrfs-progs..."
        sudo apt install -y btrfs-progs
    fi

    if grep -q "$uuid" /etc/fstab; then
        echo "Entry for UUID=$uuid already exists in /etc/fstab — skipping."
        return 0
    fi

    echo "Adding /home entry to /etc/fstab..."
    local mount_opts="defaults"
    if [[ "$fstype" == "btrfs" ]]; then
        mount_opts="defaults,subvol=@home"
    fi
    echo "UUID=$uuid  /home  $fstype  $mount_opts  0  0" | sudo tee -a /etc/fstab
    echo "Done."
}

action_install_claude() {
    if ! command -v npm &>/dev/null; then
        echo "Installing npm..."
        sudo apt install -y npm
    fi
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
}

action_setup_private() {
    if ! dpkg -s ecryptfs-utils &>/dev/null; then
        echo "Installing ecryptfs-utils..."
        sudo apt install -y ecryptfs-utils
    fi
    echo "Running ecryptfs-setup-private..."
    ecryptfs-setup-private
}

action_install_chrome() {
    echo "Adding Google Chrome repository..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    echo "Installing Google Chrome..."
    sudo apt install -y google-chrome-stable
}

action_install_cinnamon() {
    echo "Installing Cinnamon desktop..."
    sudo apt install -y cinnamon-desktop-environment
}

# ---------------------------------------------------------------------------
# Menu registry — display name and corresponding function name, in order
# ---------------------------------------------------------------------------

MENU_ITEMS=(
    "Setup home partition (fstab + btrfs-progs)"
    "Install Claude Code"
    "Setup private directory (ecryptfs-setup-private)"
    "Install Google Chrome"
    "Install Cinnamon desktop"
)

MENU_FNS=(
    "action_setup_home"
    "action_install_claude"
    "action_setup_private"
    "action_install_chrome"
    "action_install_cinnamon"
)

# ---------------------------------------------------------------------------
# Main menu loop
# ---------------------------------------------------------------------------

main_menu() {
    while true; do
        echo ""
        echo "╔══════════════════════════════════════════╗"
        echo "║       Linux Laptop Customization         ║"
        echo "╚══════════════════════════════════════════╝"
        echo ""
        for i in "${!MENU_ITEMS[@]}"; do
            printf "  %2d) %s\n" "$((i + 1))" "${MENU_ITEMS[$i]}"
        done
        echo ""
        echo "   q) Quit"
        echo ""
        read -rp "Select: " choice

        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "Done."
            exit 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] \
            && (( choice >= 1 && choice <= ${#MENU_ITEMS[@]} )); then
            echo ""
            "${MENU_FNS[$((choice - 1))]}"
        else
            echo "Invalid selection: $choice"
        fi
    done
}

main_menu
