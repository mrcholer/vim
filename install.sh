#!/bin/sh
set -eu
umask 077

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

command -v vim >/dev/null 2>&1 || fail 'Install Vim 8.2 or later first.'
vim -Nu NONE -i NONE -n -es \
    -c "if has('nvim') || v:version < 802 || !has('timers') || !has('signs') || !has('float') | cquit | endif" \
    -c 'qa!' || fail 'This configuration requires full Vim 8.2 or later with +timers, +signs and +float.'

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target="$HOME/.vimrc"
plug="$HOME/.vim/autoload/plug.vim"
plugins="$HOME/.vim/plugged"

stage=$(mktemp -d "$HOME/.vim-install.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
trap 'exit 1' HUP INT TERM

mkdir -p "$HOME/.vim/autoload"
if [ ! -s "$plug" ]; then
    command -v curl >/dev/null 2>&1 || fail 'Install curl to download vim-plug.'
    printf '%s\n' 'Downloading vim-plug...'
    curl -fsSL --connect-timeout 10 --max-time 60 \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
        -o "$stage/plug.vim" || fail 'Could not download vim-plug. Check your connection and retry.'
    [ -s "$stage/plug.vim" ] || fail 'The vim-plug download was empty.'
    mv -f -- "$stage/plug.vim" "$plug"
fi

plugins_present() {
    [ -s "$plugins/nerdtree/plugin/NERD_tree.vim" ] &&
    [ -s "$plugins/vim-devicons/plugin/webdevicons.vim" ] &&
    [ -s "$plugins/onedark.vim/colors/onedark.vim" ]
}

if ! plugins_present; then
    command -v git >/dev/null 2>&1 || fail 'Install Git to download Vim plugins.'
    printf '%s\n' 'Installing NERDTree, vim-devicons and onedark...'
    GIT_TERMINAL_PROMPT=0 vim -Nu "$repo/vimrc" -i NONE -n -es \
        --cmd 'let g:vim_config_installing = 1' \
        -c 'PlugInstall --sync' -c 'qa!' ||
        fail 'Vim plugin installation failed. Check your connection and retry.'
    plugins_present || fail "One or more plugins are missing in $plugins. Check your connection and retry."
fi

vim -Nu "$repo/vimrc" -i NONE -n -es \
    --cmd 'let g:vim_config_installing = 1' \
    -c "if !empty(v:errmsg) || !exists(':NERDTreeToggle') || !exists('*WebDevIconsGetFileTypeSymbol') | cquit | endif" \
    -c 'qa!' || fail 'The new config failed its startup check. Your existing vimrc was preserved.'

[ ! -d "$target" ] || fail "$target points to a directory."

if [ "$(uname -s)" = Darwin ]; then
    font_dir="$HOME/Library/Fonts"
else
    font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
fi
font_source="$repo/icons/fonts/VimTerminalMonoWideIcons-Regular.ttf"
font_target="$font_dir/VimTerminalMonoWideIcons-Regular.ttf"
[ -s "$font_source" ] || fail 'The bundled file icon font is missing.'
notice_dir="${XDG_DATA_HOME:-$HOME/.local/share}/doc/vim-file-icons"
mkdir -p "$font_dir" "$notice_dir"
install -m 644 "$repo/icons/fonts/NOTICE.md" "$repo/icons/fonts/DejaVu-Notices.txt" \
    "$repo/icons/fonts/Seti-Notices.txt" "$notice_dir"

font_changed=0
if ! cmp -s "$font_source" "$font_target"; then
    install -m 644 "$font_source" "$font_target"
    font_changed=1
fi

if command -v fc-cache >/dev/null 2>&1; then
    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"
    mkdir -p "$config_dir"
    font_config="$config_dir/51-vim-terminal-mono.conf"
    if [ ! -e "$font_config" ] && [ ! -L "$font_config" ]; then
        install -m 644 "$repo/icons/fonts/51-vim-terminal-mono.conf" "$font_config"
    fi
    fc-cache -f "$font_dir" ||
        printf '%s\n' 'Font cache refresh failed. Select the font after restarting your terminal.' >&2
fi

# An open GNOME Terminal server can cache the old font until it restarts.
if [ "$font_changed" -eq 1 ] && command -v sha256sum >/dev/null 2>&1; then
    server="${GNOME_TERMINAL_SERVICE:-}"
    if [ -z "$server" ] && command -v gdbus >/dev/null 2>&1; then
        server=$(gdbus call --session --dest org.freedesktop.DBus \
            --object-path /org/freedesktop/DBus --timeout 2 \
            --method org.freedesktop.DBus.GetNameOwner org.gnome.Terminal 2>/dev/null | cut -d "'" -f 2)
    fi
    if [ -n "$server" ]; then
        printf '%s\n%s' "${DBUS_SESSION_BUS_ADDRESS:-}" "$server" |
            sha256sum | cut -d ' ' -f 1 > "$HOME/.vim/wide-icons-cached-terminal"
    fi
fi

cp -- "$repo/vimrc" "$stage/vimrc"
if [ -e "$target" ] || [ -L "$target" ]; then
    backup=$(mktemp -d "$HOME/.vimrc-backup.XXXXXXXX")
    if [ -e "$target" ]; then
        cp -L -- "$target" "$backup/vimrc"
    else
        cp -P -- "$target" "$backup/vimrc"
    fi
    printf 'Previous config saved to %s\n' "$backup/vimrc"
fi
mv -f -- "$stage/vimrc" "$target"

printf '%s\n' "Installed $target" \
    "Installed the file icon font at $font_target" \
    'Restart the terminal. If it uses a custom font, select Vim Terminal Mono Wide Icons.' \
    'Open Vim with vim . or vim path/to/file.' \
    'Use VIM_WIDE_ICONS=0 vim for a Nerd Font or VIM_PLAIN_ICONS=1 vim to hide icons.' \
    'Ctrl-b opens the file tree, Ctrl-j opens the terminal, and Space ? shows the keys.'
