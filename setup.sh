#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Actions — add a function here and a matching entry in MENU_ITEMS/MENU_FNS
# ---------------------------------------------------------------------------


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

action_cinnamon_set_suspend_shortcut() {
    gsettings set org.cinnamon.desktop.keybindings.media-keys suspend "['<Primary><Super>z']"
    echo "Ctrl+Super+Z bound to suspend."
}

action_cinnamon_set_lock_shortcut() {
    gsettings set org.cinnamon.desktop.keybindings.media-keys screensaver "['<Control><Alt>l', 'XF86ScreenSaver', '<Primary><Super>l']"
    echo "Ctrl+Super+L bound to lock screen."
}

action_cinnamon_set_text_scaling() {
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.2
    echo "Text scaling factor set to 1.2."
}

action_cinnamon_set_workspace_keybindings() {
    gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 6
    echo "  6 workspaces configured"

    local schema="org.cinnamon.desktop.keybindings.wm"
    # Super+Fn keys (F1-F6) to switch to workspace 1-6
    gsettings set "$schema" switch-to-workspace-1 "['<Super>AudioMute']"
    gsettings set "$schema" switch-to-workspace-2 "['<Super>AudioLowerVolume']"
    gsettings set "$schema" switch-to-workspace-3 "['<Super>AudioRaiseVolume']"
    gsettings set "$schema" switch-to-workspace-4 "['<Super>AudioMicMute']"
    gsettings set "$schema" switch-to-workspace-5 "['<Super>MonBrightnessDown']"
    gsettings set "$schema" switch-to-workspace-6 "['<Super>MonBrightnessUp']"
    # Shift+Fn keys (F1-F6) to move window to workspace 1-6
    gsettings set "$schema" move-to-workspace-1 "['<Shift>AudioMute']"
    gsettings set "$schema" move-to-workspace-2 "['<Shift>AudioLowerVolume']"
    gsettings set "$schema" move-to-workspace-3 "['<Shift>AudioRaiseVolume']"
    gsettings set "$schema" move-to-workspace-4 "['<Shift>AudioMicMute']"
    gsettings set "$schema" move-to-workspace-5 "['<Shift>MonBrightnessDown']"
    gsettings set "$schema" move-to-workspace-6 "['<Shift>MonBrightnessUp']"
    echo "  Workspace keybindings set (Super+F1-F6 to switch, Shift+F1-F6 to move window)"
}

action_cinnamon_set_panel_autohide() {
    dconf write /org/cinnamon/panels-autohide "['1:true']"
    dconf write /org/cinnamon/panels-show-delay "['1:500']"
    dconf write /org/cinnamon/panels-hide-delay "['1:250']"
    echo "Panel auto-hide enabled (show delay: 500ms, hide delay: 250ms)."
}

action_cinnamon_ui() {
    while true; do
        echo ""
        echo "Cinnamon UI"
        echo ""
        echo "  1) Set Super+Return to launch terminal"
        echo "  2) Set Ctrl+Super+C to launch browser"
        echo "  3) Set Ctrl+Super+X to launch emacs"
        echo "  4) Bind Ctrl+Super+Z to suspend"
        echo "  5) Bind Ctrl+Super+L to lock screen"
        echo "  6) Set text scaling factor to 1.2"
        echo "  7) Enable panel auto-hide (show: 500ms, hide: 250ms)"
        echo "  8) Configure workspaces (6 static; Super+F1-F6 to switch, Shift+F1-F6 to move)"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_cinnamon_set_terminal_launcher ;;
            2) action_cinnamon_set_browser_launcher ;;
            3) action_cinnamon_set_emacs_launcher ;;
            4) action_cinnamon_set_suspend_shortcut ;;
            5) action_cinnamon_set_lock_shortcut ;;
            6) action_cinnamon_set_text_scaling ;;
            7) action_cinnamon_set_panel_autohide ;;
            8) action_cinnamon_set_workspace_keybindings ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_gnome50_set_terminal_launcher() {
    gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>Return']"
    echo "Super+Return bound to terminal launcher."
}

action_gnome50_set_browser_launcher() {
    local schema="org.gnome.settings-daemon.plugins.media-keys"
    local base_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

    local raw_list
    raw_list=$(gsettings get "$schema" custom-keybindings 2>/dev/null)

    local slot=0
    while [[ "$raw_list" == *"custom$slot"* ]]; do
        slot=$((slot + 1))
    done
    local key="custom$slot"
    local path="$base_path/$key/"

    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name "Launch Browser"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command "x-www-browser"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" binding "<Primary><Super>c"

    if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" ]]; then
        gsettings set "$schema" custom-keybindings "['$path']"
    else
        gsettings set "$schema" custom-keybindings "${raw_list%]}, '$path']"
    fi

    echo "Ctrl+Super+C bound to x-www-browser (slot $key)."
}

action_gnome50_set_emacs_launcher() {
    local schema="org.gnome.settings-daemon.plugins.media-keys"
    local base_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

    local raw_list
    raw_list=$(gsettings get "$schema" custom-keybindings 2>/dev/null)

    local slot=0
    while [[ "$raw_list" == *"custom$slot"* ]]; do
        slot=$((slot + 1))
    done
    local key="custom$slot"
    local path="$base_path/$key/"

    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name "Launch Emacs"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command 'bash -c "cd $HOME && exec /usr/bin/emacs"'
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" binding "<Primary><Super>x"

    if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" ]]; then
        gsettings set "$schema" custom-keybindings "['$path']"
    else
        gsettings set "$schema" custom-keybindings "${raw_list%]}, '$path']"
    fi

    echo "Ctrl+Super+X bound to emacs (slot $key)."
}

action_gnome50_set_suspend_shortcut() {
    gsettings set org.gnome.settings-daemon.plugins.media-keys suspend "['<Primary><Super>z']"
    echo "Ctrl+Super+Z bound to suspend."
}

action_gnome50_set_lock_shortcut() {
    gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Control><Alt>l', 'XF86ScreenSaver', '<Primary><Super>l']"
    echo "Ctrl+Super+L bound to lock screen."
}

action_gnome50_set_workspace_keybindings() {
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 6
    echo "  6 static workspaces configured"

    local schema="org.gnome.desktop.wm.keybindings"
    gsettings set "$schema" switch-to-workspace-1 "['<Super>AudioMute']"
    gsettings set "$schema" switch-to-workspace-2 "['<Super>AudioLowerVolume']"
    gsettings set "$schema" switch-to-workspace-3 "['<Super>AudioRaiseVolume']"
    gsettings set "$schema" switch-to-workspace-4 "['<Super>AudioMicMute']"
    gsettings set "$schema" switch-to-workspace-5 "['<Super>MonBrightnessDown']"
    gsettings set "$schema" switch-to-workspace-6 "['<Super>MonBrightnessUp']"
    gsettings set "$schema" move-to-workspace-1 "['<Shift>AudioMute']"
    gsettings set "$schema" move-to-workspace-2 "['<Shift>AudioLowerVolume']"
    gsettings set "$schema" move-to-workspace-3 "['<Shift>AudioRaiseVolume']"
    gsettings set "$schema" move-to-workspace-4 "['<Shift>AudioMicMute']"
    gsettings set "$schema" move-to-workspace-5 "['<Shift>MonBrightnessDown']"
    gsettings set "$schema" move-to-workspace-6 "['<Shift>MonBrightnessUp']"
    echo "  Workspace keybindings set (Super+F1-F6 to switch, Shift+F1-F6 to move window)"
}

action_gnome50_ui() {
    while true; do
        echo ""
        echo "Gnome 50 (Ubuntu 26.04)"
        echo ""
        echo "  1) Set Super+Return to launch terminal"
        echo "  2) Set Ctrl+Super+C to launch browser"
        echo "  3) Set Ctrl+Super+X to launch emacs"
        echo "  4) Bind Ctrl+Super+Z to suspend"
        echo "  5) Bind Ctrl+Super+L to lock screen"
        echo "  6) Configure workspaces (6 static; Super+F1-F6 to switch, Shift+F1-F6 to move)"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_gnome50_set_terminal_launcher ;;
            2) action_gnome50_set_browser_launcher ;;
            3) action_gnome50_set_emacs_launcher ;;
            4) action_gnome50_set_suspend_shortcut ;;
            5) action_gnome50_set_lock_shortcut ;;
            6) action_gnome50_set_workspace_keybindings ;;
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
        echo "  3) Gnome 50 (Ubuntu 26.04)"
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
            3) action_gnome50_ui ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_local_symlinks() {
    local pairs=(
        "$SCRIPT_DIR/dot-files/dot-bash_aliases|$HOME/.bash_aliases"
        "$SCRIPT_DIR/dot-files/dot-gitconfig|$HOME/.gitconfig"
    )

    for pair in "${pairs[@]}"; do
        local src="${pair%%|*}"
        local dst="${pair##*|}"

        if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
            echo "Already linked: $dst -> $src"
        elif [[ -L "$dst" ]]; then
            echo "ERROR: $dst is a symlink to a different target — remove it manually first."
        elif [[ -e "$dst" ]]; then
            echo "ERROR: $dst exists and is not a symlink — remove it manually first."
        else
            ln -sf "$src" "$dst"
            echo "Linked: $dst -> $src"
        fi
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

    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "Already linked: $dst -> $src"
    elif [[ -L "$dst" ]]; then
        echo "ERROR: $dst is a symlink to a different target — remove it manually first."
    elif [[ -e "$dst" ]]; then
        echo "ERROR: $dst exists and is not a symlink — remove it manually first."
    else
        ln -sf "$src" "$dst"
        echo "Linked: $dst -> $src"
    fi
}

action_pivot_github_origin() {
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
    if ! command -v curl &>/dev/null; then
        echo "Installing curl..."
        sudo apt install -y curl
    fi
    echo "Adding Google Chrome repository..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    echo "Installing Google Chrome..."
    sudo apt install -y google-chrome-stable
}

# TODO: check out other system tools -
# iotop, nmap, usb-creator-gtk, sysstat, traceroute, net-tools;

action_install_system_utils() {
    echo "Installing system utilities..."
    sudo apt install -y baobab httpie gparted btop mg ripgrep
}

action_install_office() {
    echo "Installing office software..."
    sudo apt install -y xournal
}

action_install_media() {
    echo "Installing media software..."
    sudo apt install -y ubuntu-restricted-extras digikam exiftool ffmpeg gimp gscan2pdf vlc
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

action_install_dropbox_unpack() {
    if [[ ! -d "$HOME/Dropbox" && ! -d "$HOME/.dropbox" ]]; then
        echo "WARNING: Neither ~/Dropbox nor ~/.dropbox exist."
        echo "If you copy those directories from another machine first, Dropbox can"
        echo "resume syncing rather than downloading everything from scratch."
        read -rp "Continue anyway? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || return 0
    fi
    echo "Downloading Dropbox..."
    curl -fsSL "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xvzf - -C "$HOME"
    echo "Done."
}

action_install_dropbox_cli() {
    echo "Downloading Dropbox CLI helper..."
    sudo curl -fsSL "https://www.dropbox.com/download?dl=packages/dropbox.py" \
        -o /usr/local/bin/dropbox
    sudo chmod +x /usr/local/bin/dropbox
    echo "Installed: /usr/local/bin/dropbox"
}

action_dropbox_autostart() {
    local autostart_dir="$HOME/.config/autostart"
    local desktop_file="$autostart_dir/dropbox.desktop"

    if [[ -f "$desktop_file" ]]; then
        echo "Autostart entry already exists: $desktop_file"
        return 0
    fi

    mkdir -p "$autostart_dir"
    cat > "$desktop_file" <<'EOF'
[Desktop Entry]
Type=Application
Name=Dropbox
Exec=dropbox start
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
    echo "Created: $desktop_file"
}

action_dropbox_locate_partition() {
    local partlabel_path="/dev/disk/by-partlabel/Dropbox"
    local mount_target="/home/dpb/Dropbox"

    if [[ ! -e "$partlabel_path" ]]; then
        echo "No partition with label 'Dropbox' was found."
        return 0
    fi

    local device fstype uuid
    device=$(readlink -f "$partlabel_path")
    fstype=$(lsblk -no FSTYPE "$device")
    uuid=$(lsblk -no UUID "$device")

    echo "Found partition: $device (type: $fstype, UUID: $uuid)"

    if grep -q "$uuid" /etc/fstab; then
        echo "Entry for UUID=$uuid already exists in /etc/fstab — skipping."
        return 0
    fi

    sudo mkdir -p "$mount_target"

    local mount_opts="defaults"
    if [[ "$fstype" == "btrfs" ]]; then
        mount_opts="defaults,subvol=@Dropbox"
    fi

    echo "Adding $mount_target entry to /etc/fstab..."
    echo "UUID=$uuid  $mount_target  $fstype  $mount_opts  0  0" | sudo tee -a /etc/fstab
    echo "Done."
}

action_dropbox_mount() {
    local mount_target="/home/dpb/Dropbox"

    if mountpoint -q "$mount_target"; then
        echo "$mount_target is already mounted."
        return 0
    fi

    echo "Mounting $mount_target..."
    sudo mount "$mount_target"
    echo "Done."
}

action_dropbox_symlink_documents() {
    local src="$HOME/Dropbox/Documents"
    local dst="$HOME/Documents"

    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "Already linked: $dst -> $src"
        return 0
    fi

    if [[ -e "$dst" && ! -L "$dst" ]]; then
        if [[ -d "$dst" && -z "$(ls -A "$dst")" ]]; then
            rmdir "$dst"
        else
            echo "ERROR: $dst exists and is not an empty directory — remove it manually first."
            return 1
        fi
    fi

    ln -sf "$src" "$dst"
    echo "Linked: $dst -> $src"
}

action_install_dropbox() {
    while true; do
        echo ""
        echo "Dropbox"
        echo ""
        echo "  1) Add Dropbox Partition to fstab"
        echo "  2) Mount Dropbox Partition"
        echo "  3) Install Dropbox"
        echo "  4) Install Dropbox CLI helper"
        echo "  5) Add 'dropbox start' to login startup"
        echo "  6) Symlink Documents -> Dropbox/Documents"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_dropbox_locate_partition ;;
            2) action_dropbox_mount ;;
            3) action_install_dropbox_unpack ;;
            4) action_install_dropbox_cli ;;
            5) action_dropbox_autostart ;;
            6) action_dropbox_symlink_documents ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
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

action_dell_printer_install_prereqs() {
    echo "Adding i386 architecture..."
    sudo dpkg --add-architecture i386
    sudo apt update
    echo "Installing prerequisite packages..."
    sudo apt install -y libc6:i386 libc6-dev:i386 libcupsimage2:i386 lib32stdc++6 lib32z1
    echo "Done."
}

action_dell_printer_install_driver() {
    local pkg="$SCRIPT_DIR/packages/xerox-phaser-6000-6010_1.0-1_i386.deb"
    echo "Installing printer driver: $(basename "$pkg")..."
    sudo dpkg -i "$pkg"
    echo "Done."
}

action_dell_printer_configure() {
    echo "Discovering Dell C1760w on network (this may take 30 seconds)..."
    local device_uri
    device_uri=$(lpinfo -v 2>/dev/null | grep -i "C1760" | awk '{print $2}' | head -1)
    if [[ -z "$device_uri" ]]; then
        echo "ERROR: Dell C1760w not found on network."
        return 1
    fi
    echo "Found: $device_uri"

    local ppd_model
    ppd_model=$(lpinfo -m 2>/dev/null | grep -i "Phaser.*6000B\|6000B.*Phaser" | awk '{print $1}' | head -1)
    if [[ -z "$ppd_model" ]]; then
        echo "ERROR: Xerox Phaser 6000B PPD not found — install the driver first."
        return 1
    fi
    echo "Using PPD: $ppd_model"

    sudo lpadmin -p "Dell-C1760w" -E -v "$device_uri" -m "$ppd_model"
    echo "Printer configured successfully."
}

action_dell_printer_support() {
    while true; do
        echo ""
        echo "Dell Printer Support"
        echo ""
        echo "  1) Install prerequisite packages"
        echo "  2) Install printer driver"
        echo "  3) Configure printer"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_dell_printer_install_prereqs ;;
            2) action_dell_printer_install_driver ;;
            3) action_dell_printer_configure ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_remove_firefox_thunderbird() {
    for snap_pkg in firefox thunderbird; do
        if snap list "$snap_pkg" &>/dev/null; then
            sudo snap remove --purge "$snap_pkg"
        fi
    done
    sudo apt-get remove --purge -y firefox thunderbird

    local seed_dir="/var/lib/snapd/seed"
    sudo rm -f "$seed_dir"/snaps/firefox_*.snap \
               "$seed_dir"/snaps/thunderbird_*.snap \
               "$seed_dir"/assertions/firefox_*.assert \
               "$seed_dir"/assertions/thunderbird_*.assert
    sudo sed -i '/^  -$/{N;N;N;/name: firefox\|name: thunderbird/d}' "$seed_dir/seed.yaml"

    echo "Firefox and Thunderbird removed."
}

action_checkout_bin_scripts() {
    if [[ -e "$HOME/bin" ]]; then
        echo "ERROR: $HOME/bin already exists — remove it manually first."
        return 1
    fi
    (cd "$HOME" && git clone git@linode.donbennett.org:dpb-bin bin)
}

action_install_filesystem_utils() {
    sudo apt-get install -y ecryptfs-utils cryptsetup sshfs exfatprogs exfat-fuse nfs-common btrfs-progs
}

action_install_pyenv() {
    if [[ -d "$HOME/.pyenv" ]]; then
        echo "pyenv already installed at $HOME/.pyenv"
        return 0
    fi

    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        gcc \
        libbz2-dev zlib1g-dev liblzma-dev \
        libsqlite3-dev libgdbm-dev \
        libncurses-dev libreadline-dev uuid-dev libffi-dev libssl-dev \
        tk-dev

    git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
    (cd "$HOME/.pyenv" && src/configure && make -C src)

    if ! grep -q 'PYENV_ROOT' "$HOME/.bashrc"; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$HOME/.bashrc"
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$HOME/.bashrc"
        echo 'eval "$(pyenv init -)"' >> "$HOME/.bashrc"
        echo "pyenv init added to $HOME/.bashrc"
    else
        echo "pyenv init already present in $HOME/.bashrc — skipping"
    fi

    export PATH="$HOME/.pyenv/bin:$PATH"
    echo "pyenv installed at $HOME/.pyenv"
}

action_install_cpython_latest() {
    if [[ ! -d "$HOME/.pyenv" ]]; then
        echo "ERROR: pyenv is not installed — run 'Python (pyenv)' first."
        return 1
    fi

    # Ensure pyenv is in PATH for this session
    export PATH="$HOME/.pyenv/bin:$PATH"

    local latest
    latest=$(pyenv install --list | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    if [[ -z "$latest" ]]; then
        echo "ERROR: Could not determine latest CPython version."
        return 1
    fi

    echo "Installing CPython $latest..."
    pyenv install --verbose "$latest"
    pyenv global "$latest"
    echo "CPython $latest installed and set as global default."
}

action_install_nvm_node() {
    if [[ -d "$HOME/.nvm" ]]; then
        echo "nvm already installed at $HOME/.nvm"
        return 0
    fi

    local nvm_version
    nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$nvm_version" ]]; then
        echo "ERROR: Could not determine latest nvm version."
        return 1
    fi

    echo "Installing nvm $nvm_version..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash

    # Source nvm in the current shell session
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"

    echo "Installing latest Node.js..."
    nvm install node
    echo "nvm $nvm_version and Node.js installed."
}

action_remove_unattended_upgrades() {
    sudo apt-get remove --purge -y unattended-upgrades
    echo "unattended-upgrades removed."
}

action_install_zoom() {
    local tmp
    tmp=$(mktemp --suffix=.deb)
    echo "Downloading Zoom..."
    curl -fsSL -o "$tmp" https://zoom.us/client/latest/zoom_amd64.deb
    sudo apt-get install -y "$tmp"
    rm -f "$tmp"
    echo "Zoom installed."
}

action_install_software() {
    while true; do
        echo ""
        echo "Add/Remove Software"
        echo ""
        echo "  1) Checkout ~/bin scripts"
        echo "  2) Filesystem Utils (ecryptfs-utils, cryptsetup, sshfs, exfatprogs, exfat-fuse, nfs-common, btrfs-progs)"
        echo "  3) System Utils (baobab, httpie, gparted, btop, mg, ripgrep)"
        echo "  4) Office (xournal)"
        echo "  5) Media (ubuntu-restricted-extras, digikam, ffmpeg, gimp, gscan2pdf, vlc)"
        echo "  6) Devtools (jq, make)"
        echo "  7) Dropbox"
        echo "  8) Install nvm & node"
        echo "  9) Clojure"
        echo " 10) Python (pyenv)"
        echo " 11) Python (latest CPython)"
        echo " 12) Zoom"
        echo " 13) Remove Firefox & Thunderbird"
        echo " 14) Remove unattended-upgrades"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_checkout_bin_scripts ;;
            2) action_install_filesystem_utils ;;
            3) action_install_system_utils ;;
            4) action_install_office ;;
            5) action_install_media ;;
            6) action_install_devtools ;;
            7) action_install_dropbox ;;
            8) action_install_nvm_node ;;
            9) action_install_clojure ;;
            10) action_install_pyenv ;;
            11) action_install_cpython_latest ;;
            12) action_install_zoom ;;
            13) action_remove_firefox_thunderbird ;;
            14) action_remove_unattended_upgrades ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_hibernate_configure_swap() {
    local swap_uuid
    swap_uuid=$(sudo blkid -t TYPE=swap -s UUID -o value | head -1)
    if [[ -z "$swap_uuid" ]]; then
        echo "ERROR: No swap partition found on this system."
        return 1
    fi
    echo "Found swap partition UUID: $swap_uuid"

    local fstab="/etc/fstab"

    if grep -qF "UUID=$swap_uuid" "$fstab"; then
        echo "UUID=$swap_uuid already present in $fstab."
    else
        echo "Adding swap partition to $fstab..."
        echo "UUID=$swap_uuid  none  swap  sw  0  0" | sudo tee -a "$fstab" > /dev/null
        echo "Added."
    fi

    # Find any file-based swap entry (absolute path, not a UUID= device, type swap)
    local swapfile_line swapfile_path
    swapfile_line=$(grep -E '^[[:space:]]*/[^[:space:]]+[[:space:]]' "$fstab" \
        | grep -v '^[[:space:]]*#' \
        | awk '$3=="swap" && $1 !~ /^UUID=/' \
        | head -1 || true)
    if [[ -n "$swapfile_line" ]]; then
        swapfile_path=$(echo "$swapfile_line" | awk '{print $1}')
        echo "Found swapfile entry in fstab: $swapfile_path — removing..."
        if swapon --show --noheadings | awk '{print $1}' | grep -qF "$swapfile_path"; then
            echo "Disabling $swapfile_path..."
            sudo swapoff "$swapfile_path"
        fi
        sudo sed -i "\|^[[:space:]]*$swapfile_path[[:space:]]|d" "$fstab"
        echo "Removed $swapfile_path from $fstab."
    fi

    echo "Synchronizing active swap with fstab..."
    sudo swapoff -a 2>/dev/null || true
    sudo swapon -a
    echo "Active swap:"
    swapon --show
}

action_hibernate_configure_grub() {
    local swap_uuid
    swap_uuid=$(sudo blkid -t TYPE=swap -s UUID -o value | head -1)
    if [[ -z "$swap_uuid" ]]; then
        echo "ERROR: No swap partition found."
        return 1
    fi
    echo "Swap partition UUID: $swap_uuid"

    local grub_file="/etc/default/grub"
    local resume_param="resume=UUID=$swap_uuid"

    if grep -qF "$resume_param" "$grub_file"; then
        echo "GRUB already has $resume_param — nothing to do."
        return 0
    fi

    sudo cp "$grub_file" "${grub_file}.bak"
    echo "Backed up $grub_file to ${grub_file}.bak"

    if grep -q "resume=" "$grub_file"; then
        sudo sed -i "s|resume=[^[:space:]\"]*|$resume_param|g" "$grub_file"
        echo "Updated existing resume= to $resume_param."
    else
        sudo sed -i "s|^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"|\1 $resume_param\"|" "$grub_file"
        echo "Added $resume_param to GRUB_CMDLINE_LINUX_DEFAULT."
    fi

    echo "Running update-grub..."
    sudo update-grub
    echo "Done. Reboot required for changes to take effect."
}

action_hibernate_set_shortcut() {
    local cmd="sudo systemctl hibernate"
    local de="${XDG_CURRENT_DESKTOP:-}"

    if [[ "$de" == *"GNOME"* ]]; then
        local schema="org.gnome.settings-daemon.plugins.media-keys"
        local base_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
        local raw_list
        raw_list=$(gsettings get "$schema" custom-keybindings 2>/dev/null)
        local slot=0
        while [[ "$raw_list" == *"custom$slot"* ]]; do
            slot=$((slot + 1))
        done
        local key="custom$slot"
        local path="$base_path/$key/"
        gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name "Hibernate"
        gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command "$cmd"
        gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" binding "<Primary><Super>h"
        if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" ]]; then
            gsettings set "$schema" custom-keybindings "['$path']"
        else
            gsettings set "$schema" custom-keybindings "${raw_list%]}, '$path']"
        fi
        echo "Ctrl+Super+H bound to hibernate (GNOME, slot $key)."
    elif [[ "$de" == *"X-Cinnamon"* || "$de" == *"CINNAMON"* ]]; then
        local schema="org.cinnamon.desktop.keybindings"
        local base_path="/org/cinnamon/desktop/keybindings/custom-keybindings"
        local raw_list
        raw_list=$(gsettings get "$schema" custom-list 2>/dev/null)
        local slot=0
        while [[ "$raw_list" == *"custom$slot"* ]]; do
            slot=$((slot + 1))
        done
        local key="custom$slot"
        local path="$base_path/$key/"
        gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" name "Hibernate"
        gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" command "$cmd"
        gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:$path" binding "['<Primary><Super>h']"
        if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" ]]; then
            gsettings set "$schema" custom-list "['$key']"
        else
            gsettings set "$schema" custom-list "${raw_list%]}, '$key']"
        fi
        echo "Ctrl+Super+H bound to hibernate (Cinnamon, slot $key)."
    else
        echo "ERROR: Unsupported or undetected desktop environment: '${de:-<unset>}'."
        echo "Supported: GNOME, X-Cinnamon."
        return 1
    fi
}

action_hibernate_add_sudoers() {
    local sudoers_file="/etc/sudoers.d/dpb-systemctl"
    local rule="dpb ALL=(ALL) NOPASSWD: /usr/bin/systemctl *"

    if [[ -f "$sudoers_file" ]] && grep -qF "$rule" "$sudoers_file"; then
        echo "Rule already present in $sudoers_file."
        return 0
    fi

    local tmp
    tmp=$(mktemp)
    echo "$rule" > "$tmp"

    if ! visudo -c -f "$tmp" &>/dev/null; then
        echo "ERROR: sudoers syntax check failed."
        rm -f "$tmp"
        return 1
    fi

    sudo install -m 440 -o root -g root "$tmp" "$sudoers_file"
    rm -f "$tmp"
    echo "Written: $sudoers_file"
    echo "  $rule"
}

action_power_management_changes() {
    local logind_conf="/etc/systemd/logind.conf"
    local de="${XDG_CURRENT_DESKTOP:-}"

    if [[ "$de" == *"GNOME"* ]]; then
        local schema="org.gnome.settings-daemon.plugins.power"
        echo "Applying GNOME power management settings..."

        gsettings set "$schema" lid-close-ac-action 'nothing'
        echo "  AC lid-close → nothing"

        gsettings set "$schema" sleep-inactive-battery-type 'blank'
        gsettings set "$schema" sleep-inactive-battery-timeout 300
        echo "  Battery idle screen-off → 5 minutes"

        gsettings set "$schema" lid-close-battery-action 'nothing'
        echo "  Battery lid-close → nothing"

        if gsettings describe "$schema" button-power &>/dev/null; then
            gsettings set "$schema" button-power 'nothing'
            echo "  Power button → nothing"
        fi

    elif [[ "$de" == *"X-Cinnamon"* || "$de" == *"CINNAMON"* ]]; then
        local schema="org.cinnamon.settings-daemon.plugins.power"
        echo "Applying Cinnamon power management settings..."

        gsettings set "$schema" lid-close-ac-action 'nothing'
        echo "  AC lid-close → nothing"

        # Cinnamon uses sleep-display-battery (seconds) for battery display timeout
        gsettings set "$schema" sleep-display-battery 300
        echo "  Battery idle screen-off → 5 minutes"

        gsettings set "$schema" lid-close-battery-action 'nothing'
        echo "  Battery lid-close → nothing"

        gsettings set "$schema" button-power 'nothing'
        echo "  Power button → nothing"

    else
        echo "ERROR: Unsupported or undetected desktop environment: '${de:-<unset>}'."
        echo "Supported: GNOME, X-Cinnamon."
        return 1
    fi

    echo "Applying /etc/systemd/logind.conf settings..."
    sudo cp "$logind_conf" "${logind_conf}.bak"
    echo "Backed up $logind_conf to ${logind_conf}.bak"

    for key in HandleLidSwitch HandleLidSwitchOnBattery; do
        if grep -qE "^#?${key}=" "$logind_conf"; then
            sudo sed -i "s|^#*${key}=.*|${key}=ignore|" "$logind_conf"
        else
            sudo sed -i "/^\[Login\]/a ${key}=ignore" "$logind_conf"
        fi
        echo "  ${key}=ignore"
    done

    sudo systemctl restart systemd-logind
    echo "Done."
}

action_hibernation_submenu() {
    while true; do
        echo ""
        echo "Hibernation"
        echo ""
        echo "  1) Configure swap partition in /etc/fstab (remove swapfile)"
        echo "  2) Configure GRUB resume= parameter"
        echo "  3) Run: sudo update-initramfs -u"
        echo "  4) Bind Ctrl+Super+H to hibernate"
        echo "  5) Add sudoers rule: dpb can run systemctl without password"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_hibernate_configure_swap ;;
            2) action_hibernate_configure_grub ;;
            3) sudo update-initramfs -u ;;
            4) action_hibernate_set_shortcut ;;
            5) action_hibernate_add_sudoers ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

action_configure_screensaver() {
    local de="${XDG_CURRENT_DESKTOP:-}"
    if [[ "$de" != *"Cinnamon"* ]]; then
        echo "Warning: screensaver configuration requires Cinnamon (current desktop: ${de:-unknown})"
        return
    fi

    # Delay before screensaver starts: 5 minutes
    gsettings set org.cinnamon.desktop.session idle-delay 300
    echo "  Screensaver delay → 5 minutes"

    # Do not lock when the system goes to sleep
    gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false
    echo "  Lock on sleep → disabled"

    # Do not lock when the screensaver starts
    gsettings set org.cinnamon.desktop.screensaver lock-enabled false
    echo "  Lock on screensaver → disabled"

    echo "Done."
}

action_enable_sysrq() {
    local conf="/etc/sysctl.d/99-sysrq.conf"
    if [[ -f "$conf" ]] && grep -q "^kernel.sysrq = 1" "$conf"; then
        echo "SysRq already enabled ($conf)."
        return 0
    fi
    echo "kernel.sysrq = 1" | sudo tee "$conf" > /dev/null
    sudo sysctl -p "$conf"
    echo "All SysRq functions enabled."
}

action_sleep_hibernation() {
    while true; do
        echo ""
        echo "Sleep / Hibernation / SysRq"
        echo ""
        echo "  1) Hibernation"
        echo "  2) Power Management changes"
        echo "  3) Configure Screensaver"
        echo "  4) Enable all SysRq functions"
        echo ""
        echo "  b) Back"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) action_hibernation_submenu ;;
            2) action_power_management_changes ;;
            3) action_configure_screensaver ;;
            4) action_enable_sysrq ;;
            b|B) return 0 ;;
            *) echo "Invalid selection: $choice" ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Menu registry — display name and corresponding function name, in order
# ---------------------------------------------------------------------------

MENU_ITEMS=(
    "Install Claude Code"
    "Local Symlinks (dotfiles, \$HOME/bin)"
    "Setup private directory (ecryptfs-setup-private)"
    "Setup SSH keys (copy, decrypt, fix permissions)"
    "Pivot GitHub origin URL to SSH (git@github.com)"
    "Install Emacs (copy dot-emacs)"
    "Install Google Chrome"
    "Customize UI"
    "Add/Remove Software"
    "Dell Printer Support"
    "Sleep / Hibernation / SysRq"
)

MENU_FNS=(
    "action_install_claude"
    "action_local_symlinks"
    "action_setup_private"
    "action_setup_ssh"
    "action_pivot_github_origin"
    "action_install_emacs"
    "action_install_chrome"
    "action_customize_ui"
    "action_install_software"
    "action_dell_printer_support"
    "action_sleep_hibernation"
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
