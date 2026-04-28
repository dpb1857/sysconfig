# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal Linux laptop setup repo for Don Bennett. The primary artifact is `setup.sh` — an interactive, menu-driven bash script that configures a fresh Linux install. There are no build steps, no tests, and no CI.

## Running the script

```bash
bash setup.sh
```

The script uses `set -euo pipefail`. Any action that calls `sudo` will prompt for a password in the terminal.

## Architecture of setup.sh

The script is structured around two parallel arrays at the bottom of the file:

- `MENU_ITEMS[]` — display strings for the top-level menu
- `MENU_FNS[]` — corresponding function names, called by index

`main_menu()` loops, prints the arrays, and dispatches by index. Submenus follow the same pattern: a dedicated `action_*()` function contains its own `while true` loop with numbered items and a `b) Back` exit.

**Adding a new top-level item**: add an entry to both `MENU_ITEMS` and `MENU_FNS` (keeping them in sync), and define the corresponding `action_*()` function.

**Adding a submenu item**: add a `echo "  N) ..."` line and a matching `N) action_foo ;;` case arm inside the parent submenu function. Renumber subsequent items.

## Key conventions

- All action functions are named `action_<verb>_<noun>()` (e.g. `action_install_emacs`, `action_checkout_bin_scripts`).
- Symlink management uses a consistent 4-case idempotent pattern (already-correct link → skip; wrong-target symlink → error; non-symlink exists → error; absent → create). See `action_local_symlinks()` and `action_install_emacs()` for the canonical form.
- Desktop environment detection uses `$XDG_CURRENT_DESKTOP` and checks for `*GNOME*` vs `*X-Cinnamon*`/`*CINNAMON*`. See `action_power_management_changes()` for the pattern.
- `$SCRIPT_DIR` is the directory containing `setup.sh`, resolved at startup. Use it for all relative paths into the repo (e.g. `$SCRIPT_DIR/dot-files/dot-emacs`).

## Repo layout

- `setup.sh` — the main setup script
- `dot-files/` — dotfiles symlinked into `$HOME` by `action_local_symlinks()` and `action_install_emacs()`
- `elisp/` — personal Emacs Lisp files (loaded via `~/.emacs` → `dot-files/dot-emacs`)
- `ssh/` — SSH config and GPG-encrypted key files, deployed by `action_setup_ssh()`
- `packages/` — local `.deb` files (Xerox printer driver)
- `notes/` — freeform setup notes, not used by the script
