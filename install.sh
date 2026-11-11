#!/bin/sh
# ============================================================================
# install.sh — install the agent-free Vim config
# ============================================================================
# What this installs (pure Vim, no AI / no agent / no Kitty wrapper):
#   * NERDTree file sidebar  (Ctrl-b / Ctrl-n / F3)
#   * vim-devicons file icons (needs a Nerd Font in your terminal)
#   * onedark colorscheme
#   * bottom terminal panel  (Ctrl-j)
#   * build (Ctrl-e) / run (F6) / valgrind (Space v)
#   * 42 header (F1), norm auto-fix + deep norm fix (Space x)
#   * git info in the status line, #include helper (Space i / Space I)
#   * auto-complete popup, brackets/quotes, 42 Norm indentation
#
# Nothing here opens Kitty, runs an agent, or phones home.
# ============================================================================
set -eu

VIMRC_DIR="$(cd "$(dirname "$0")" && pwd)"
VIMRC="$VIMRC_DIR/vimrc"
TARGET_VIMRC="$HOME/.vimrc"
PLUG="$HOME/.vim/autoload/plug.vim"

echo "==> Installing agent-free Vim config"

# 1) vim-plug (plugin manager)
if [ ! -f "$PLUG" ]; then
    echo "==> Downloading vim-plug"
    mkdir -p "$HOME/.vim/autoload"
    curl -fsSLo "$PLUG" \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
    echo "==> vim-plug already present"
fi

# 2) Copy the vimrc
cp "$VIMRC" "$TARGET_VIMRC"
echo "==> Wrote $TARGET_VIMRC"

# 3) Undo directory
mkdir -p "$HOME/.vim/undo"

# 4) Install plugins (NERDTree, devicons, onedark)
echo "==> Installing plugins with vim-plug (opens Vim briefly)"
vim -u "$TARGET_VIMRC" -N -n -c 'PlugInstall --sync' -c 'qall' >/dev/null 2>&1 || true

# 5) Nerd Font reminder
echo
echo "==> Done."
echo "    For file icons to show, set your terminal font to a Nerd Font"
echo "    (e.g. JetBrainsMono Nerd Font)."
echo "    Open Vim:  vim   (or vi — ~/.virc points to ~/.vimrc)"
echo "    Keys: Ctrl-b file tree | Ctrl-j terminal | Ctrl-e build | F6 run"
echo "    No agent, no AI, no Kitty wrapper is installed."
