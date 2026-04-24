#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    if ! command -v curl &>/dev/null; then
        echo "Installing curl..."
        sudo apt install -y curl
    fi
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
}

action_cinnamon_set_terminal_launcher() {
    local schema="org.cinnamon.desktop.keybindings"
    local base_path="/org/cinnamon/desktop/keybindings/custom-keybindings"

    local raw_list
    raw_list=$(gsettings get "$schema" custom-list 2>/dev/null)

    # Find next free slot
    local slot=0
    while [[ "$raw_list" == *"custom$slot"* ]]; do
        slot=$((slot + 1))
    done
    local key="custom$slot"
    local path="$base_path/$key/"

    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" name "Launch Terminal"
    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" command "x-terminal-emulator"
    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" binding "['<Super>Return']"

    if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" ]]; then
        gsettings set "$schema" custom-list "['$key']"
    else
        gsettings set "$schema" custom-list "${raw_list%]}, '$key']"
    fi

    echo "Super+Return bound to x-terminal-emulator (slot $key)."
}

action_cinnamon_set_browser_launcher() {
    local schema="org.cinnamon.desktop.keybindings"
    local base_path="/org/cinnamon/desktop/keybindings/custom-keybindings"

    local raw_list
    raw_list=$(gsettings get "$schema" custom-list 2>/dev/null)

    # Find next free slot
    local slot=0
    while [[ "$raw_list" == *"custom$slot"* ]]; do
        slot=$((slot + 1))
    done
    local key="custom$slot"
    local path="$base_path/$key/"

    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" name "Launch Browser"
    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" command "x-www-browser"
    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" binding "['<Primary><Super>c']"

    if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" ]]; then
        gsettings set "$schema" custom-list "['$key']"
    else
        gsettings set "$schema" custom-list "${raw_list%]}, '$key']"
    fi

    echo "Ctrl+Super+C bound to x-www-browser (slot $key)."
}

action_cinnamon_set_emacs_launcher() {
    local schema="org.cinnamon.desktop.keybindings"
    local base_path="/org/cinnamon/desktop/keybindings/custom-keybindings"

    local raw_list
    raw_list=$(gsettings get "$schema" custom-list 2>/dev/null)

    # Find next free slot
    local slot=0
    while [[ "$raw_list" == *"custom$slot"* ]]; do
        slot=$((slot + 1))
    done
    local key="custom$slot"
    local path="$base_path/$key/"

    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" name "Launch Emacs"
    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" command 'bash -c "cd $HOME && exec /usr/bin/emacs"'
    gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" binding "['<Primary><Super>x']"

    if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" ]]; then
        gsettings set "$schema" custom-list "['$key']"
    else
        gsettings set "$schema" custom-list "${raw_list%]}, '$key']"
    fi

    echo "Ctrl+Super+X bound to emacs (slot $key)."
}

action_cinnamon_ui() {
    while true; do
        echo ""
        echo "Cinnamon UI"
        echo ""
        echo "  1) Set Super+Return to launch terminal"
        echo "  2) Set Ctrl+Super+C to launch browser"
        echo "  3) Set Ctrl+Super+X to launch emacs"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_cinnamon_set_terminal_launcher ;;
            2) action_cinnamon_set_browser_launcher ;;
            3) action_cinnamon_set_emacs_launcher ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_customize_ui() {
    while true; do
        echo ""
        echo "UI Customization"
        echo ""
        echo "  1) Map Caps Lock to Left Control"
        echo "  2) Cinnamon UI"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1)
                # /etc/default/keyboard is the reliable persistent path for both X11 and Wayland.
                # gsettings applies to the live GNOME/Cinnamon session without a logout.
                local kb_file="/etc/default/keyboard"
                if grep -q "ctrl:nocaps" "$kb_file" 2>/dev/null; then
                    echo "Caps Lock already remapped in $kb_file."
                else
                    sudo sed -i 's/^XKBOPTIONS=.*/XKBOPTIONS="ctrl:nocaps"/' "$kb_file"
                    sudo dpkg-reconfigure -phigh keyboard-configuration
                    echo "Updated $kb_file."
                fi
                gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
                echo "Caps Lock mapped to Left Control (log out and back in if not effective immediately)."
                ;;
            2) action_cinnamon_ui ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_setup_private() {
    if ! dpkg -s ecryptfs-utils &>/dev/null; then
        echo "Installing ecryptfs-utils..."
        sudo apt install -y ecryptfs-utils
    fi
    echo "Running ecryptfs-setup-private..."
    ecryptfs-setup-private
}

action_setup_ssh() {
    local src_dir="$SCRIPT_DIR/ssh"
    local private_dir="$HOME/Private"
    local dot_ssh_store="$HOME/Private/dot-ssh"
    local dst_dir="$HOME/.ssh"

    # (a) Verify ~/Private is mounted
    if ! mountpoint -q "$private_dir"; then
        echo "ERROR: $private_dir is not mounted. Run 'ecryptfs-setup-private' and re-log in first."
        return 1
    fi

    # (b) Create ~/Private/dot-ssh if it doesn't exist
    mkdir -p "$dot_ssh_store"

    # (c) If ~/.ssh is a plain directory and non-empty, move its contents into ~/Private/dot-ssh
    if [[ -d "$dst_dir" && ! -L "$dst_dir" ]]; then
        if [[ -n "$(ls -A "$dst_dir")" ]]; then
            echo "Moving existing $dst_dir contents into $dot_ssh_store..."
            find "$dst_dir" -maxdepth 1 -mindepth 1 -exec mv -t "$dot_ssh_store/" {} +
        fi
        rmdir "$dst_dir"
    fi

    # (d) Make ~/.ssh a symlink to ~/Private/dot-ssh
    if [[ -L "$dst_dir" ]]; then
        local current_target
        current_target=$(readlink "$dst_dir")
        if [[ "$current_target" != "$dot_ssh_store" ]]; then
            echo "Relinking $dst_dir -> $dot_ssh_store (was -> $current_target)..."
            rm "$dst_dir"
            ln -s "$dot_ssh_store" "$dst_dir"
        fi
    else
        echo "Creating symlink: $dst_dir -> $dot_ssh_store"
        ln -s "$dot_ssh_store" "$dst_dir"
    fi

    # Copy files from ssh/* only if they do not already exist in ~/.ssh
    local f basename_f
    for f in "$src_dir"/*; do
        [[ -e "$f" ]] || continue
        basename_f=$(basename "$f")
        if [[ -e "$dst_dir/$basename_f" ]]; then
            echo "Skipping (already exists): $basename_f"
        else
            echo "Copying: $basename_f"
            cp -v "$f" "$dst_dir/"
        fi
    done

    echo "Decrypting *.gpg files..."
    local gpg_file decrypted
    for gpg_file in "$dst_dir"/*.gpg; do
        [[ -e "$gpg_file" ]] || continue
        decrypted="${gpg_file%.gpg}"
        if [[ -e "$decrypted" ]]; then
            echo "Skipping (already exists): $(basename "$decrypted")"
            continue
        fi
        if gpg --quiet --decrypt --output "$decrypted" "$gpg_file"; then
            rm "$gpg_file"
            echo "Decrypted: $(basename "$decrypted")"
        else
            rm -f "$decrypted"
            echo "ERROR: Failed to decrypt $(basename "$gpg_file") — leaving encrypted file in place."
        fi
    done

    echo "Fixing permissions..."
    chmod 700 "$dst_dir"
    for f in "$dst_dir"/*; do
        [[ -e "$f" ]] || continue
        case "$f" in
            *.pub) chmod 644 "$f" ;;
            *)     chmod 600 "$f" ;;
        esac
    done

    echo "Done."
}

action_install_emacs() {
    local src="$SCRIPT_DIR/dot-files/dot-emacs"
    local dst="$HOME/.emacs"

    if ! command -v emacs &>/dev/null; then
        echo "Installing Emacs..."
        sudo apt install -y emacs
    else
        echo "Emacs is already installed."
    fi

    if [[ -e "$dst" ]]; then
        echo "Skipping (already exists): $dst"
    else
        cp -v "$src" "$dst"
        echo "Done."
    fi
}

action_pivot_github_origin() {
    local gitconfig_src="$SCRIPT_DIR/dot-files/dot-gitconfig"
    local gitconfig_dst="$HOME/.gitconfig"
    if [[ -e "$gitconfig_dst" ]]; then
        echo "Skipping (already exists): $gitconfig_dst"
    else
        cp -v "$gitconfig_src" "$gitconfig_dst"
    fi

    local url
    if ! url=$(git remote get-url origin 2>/dev/null); then
        echo "ERROR: No 'origin' remote found in this git repository."
        return 1
    fi

    if [[ "$url" == git@github* ]]; then
        echo "Origin is already using SSH: $url"
    elif [[ "$url" == https://github.com/* || "$url" == http://github.com/* ]]; then
        local ssh_url
        ssh_url=$(sed 's|https\?://github\.com/|git@github.com:|' <<<"$url")
        git remote set-url origin "$ssh_url"
        echo "Converted origin URL:"
        echo "  Old: $url"
        echo "  New: $ssh_url"
    else
        echo "Origin URL is not a recognized GitHub URL: $url"
        return 1
    fi

    echo "Checking SSH key access to GitHub..."
    # ssh -T exits 1 even on success; capture output so pipefail doesn't interfere
    local ssh_out
    ssh_out=$(ssh -T git@github.com 2>&1) || true
    if grep -q "successfully authenticated" <<<"$ssh_out"; then
        echo "SSH key access confirmed."
    else
        echo "WARNING: Could not authenticate with GitHub via SSH. Check that your key is loaded (ssh-add -l) and added to your GitHub account."
    fi
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

action_install_system_utils() {
    echo "Installing system utilities..."
    sudo apt install -y baobab httpie gparted btop ripgrep
}

action_install_office() {
    echo "Installing office software..."
    sudo apt install -y xournal
}

action_install_media() {
    echo "Installing media software..."
    sudo apt install -y ubuntu-restricted-extras digikam ffmpeg gimp gscan2pdf vlc
}

action_install_devtools() {
    echo "Installing dev tools..."
    sudo apt install -y jq make
}

action_install_clojure_java() {
    if ! command -v java &>/dev/null; then
        echo "Installing Java (required for Clojure)..."
        sudo apt install -y default-jdk
    fi
    if ! command -v rlwrap &>/dev/null; then
        echo "Installing rlwrap (required for Clojure)..."
        sudo apt install -y rlwrap
    fi
    echo "Downloading Clojure installer..."
    curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh
    chmod +x linux-install.sh
    echo "Installing Clojure..."
    sudo ./linux-install.sh
    rm linux-install.sh
}

action_install_clj_kondo() {
    echo "Downloading clj-kondo installer..."
    curl -sLO https://raw.githubusercontent.com/clj-kondo/clj-kondo/master/script/install-clj-kondo
    chmod +x install-clj-kondo
    echo "Installing clj-kondo..."
    sudo ./install-clj-kondo
    rm install-clj-kondo
}

action_install_babashka() {
    echo "Downloading babashka installer..."
    curl -sLO https://raw.githubusercontent.com/babashka/babashka/master/install
    chmod +x install
    echo "Installing babashka..."
    sudo ./install
    rm install
}

action_install_clojure() {
    while true; do
        echo ""
        echo "Clojure"
        echo ""
        echo "  1) Java Clojure"
        echo "  2) clj-kondo"
        echo "  3) babashka"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_install_clojure_java ;;
            2) action_install_clj_kondo ;;
            3) action_install_babashka ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_install_software() {
    while true; do
        echo ""
        echo "Install Software"
        echo ""
        echo "  1) System Utils (baobab, httpie, gparted, btop, ripgrep)"
        echo "  2) Office (xournal)"
        echo "  3) Media (ubuntu-restricted-extras, digikam, ffmpeg, gimp, gscan2pdf, vlc)"
        echo "  4) Devtools (jq, make)"
        echo "  5) Clojure"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_install_system_utils ;;
            2) action_install_office ;;
            3) action_install_media ;;
            4) action_install_devtools ;;
            5) action_install_clojure ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Menu registry — display name and corresponding function name, in order
# ---------------------------------------------------------------------------

MENU_ITEMS=(
    "Setup home partition (fstab + btrfs-progs)"
    "Install Claude Code"
    "Setup private directory (ecryptfs-setup-private)"
    "Setup SSH keys (copy, decrypt, fix permissions)"
    "Pivot GitHub origin URL to SSH (git@github.com)"
    "Install Emacs (copy dot-emacs)"
    "Install Google Chrome"
    "Customize UI"
    "Install Software"
)

MENU_FNS=(
    "action_setup_home"
    "action_install_claude"
    "action_setup_private"
    "action_setup_ssh"
    "action_pivot_github_origin"
    "action_install_emacs"
    "action_install_chrome"
    "action_customize_ui"
    "action_install_software"
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
