# Agent-free Vim config

A Vim setup for 42 and general development with a file tree, bottom terminal,
git status, C builds, and Norminette diagnostics.

## Try it

From this checkout:

```sh
vim -u "$PWD/vimrc" .
```

With NERDTree installed, Vim opens the file tree on the left and the editor on
the right. If NERDTree is missing, use `Ctrl-b` to open Vim's built-in netrw
browser. To hide the file icons and use a text label for the git branch, launch
Vim with `VIM_PLAIN_ICONS=1`.

## Install

Use full Vim 8.2 or later with `+timers`, `+signs`, and `+float`. The
terminal panel requires `+terminal`. Tree decorations require Vim 9.0.0067
or later with `+textprop`.

```sh
./install.sh
```

The installer uses curl and Git if it needs to download vim-plug, NERDTree,
vim-devicons, or onedark. It checks that the config loads before replacing
`~/.vimrc` and prints the backup path if a previous config exists. Vim startup
uses the plugins already on disk.

The installer also copies the bundled **Vim Terminal Mono Wide Icons** font
to your user font directory. On Linux with Fontconfig, it refreshes the font
cache and makes the bundled font the preferred generic monospace font. Restart
your terminal to pick up the change. If your terminal has a custom font set,
select **Vim Terminal Mono Wide Icons** in its settings.

## Keys

| Action | Keys or command |
| --- | --- |
| Toggle file tree | `Ctrl-b`, `Ctrl-n`, or `F3` |
| Toggle terminal panel | `Ctrl-j` |
| Build with a parent Makefile or compile a C file with GCC | `Ctrl-e` |
| Run `./a.out` from Vim's working directory | `F6` |
| Insert or update a 42 header | `F1` |
| Open Norminette diagnostics | `Space n` or `:NormCheck` |
| Run a deep Norm fix and save | `Space x` |
| Add a standard C include | `Space i` or `Space I` |
| Browse or accept autocomplete suggestions | `Ctrl-n`, `Ctrl-p`, or `Tab` |
| Show key bindings | `Space ?` |

Norminette diagnostics refresh when a C file is opened or saved. Install
`norminette` to enable them. Compiler errors appear in quickfix, and
`:NormCheck` opens a location list for the current window. Source rewriting on
save is opt-in via `:NormAutoFixToggle`. Once enabled, `:NormDeepToggle`
also enables deeper rewrites for the current Vim session.

New C headers use the current login name. Set `VIM_42_USER` and
`VIM_42_EMAIL` before launching Vim to customize the generated 42 headers.
Swap recovery, persistent undo, and directory sessions live under `~/.vim`.

## File icons

The sidebar uses vim-devicons and the terminal font. The configuration includes
filename-specific icons for Docker and Compose files, package manifests and
lockfiles, TypeScript configuration, and Python project files. Extension
mappings cover C and C++ headers, TSX, JSONC, SQLite databases, and other
common formats.

The bundled font uses two cells for each supported sidebar icon while keeping
regular text monospaced. Linux graphical sessions use wide icons automatically.
To enable them on macOS or in a session without a display variable, select the
bundled font in the terminal and run `VIM_WIDE_ICONS=1 vim`. Run
`VIM_WIDE_ICONS=0 vim` to use the standard glyphs with a
[Nerd Font Mono](https://www.nerdfonts.com/font-downloads). See the
[font attributions and licenses](icons/fonts/NOTICE.md).

The PNG files under `icons/` are repository previews.

| C source | C header | Markdown | Folder | Text | Generic file |
| --- | --- | --- | --- | --- | --- |
| ![C source](icons/icon-c.png) | ![C header](icons/icon-h.png) | ![Markdown](icons/icon-md.png) | ![Folder](icons/icon-folder.png) | ![Text](icons/icon-text.png) | ![Generic file](icons/icon-file.png) |
