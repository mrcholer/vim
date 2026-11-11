# Agent-free Vim config

Pure Vim setup: **file tree sidebar, bottom terminal panel, file icons, 42 Norm
helpers, build/run, git-aware status line**. No AI, no agent panel, no Kitty
wrapper, nothing phones home.

## What's inside

| Feature | How to open |
|---|---|
| File tree sidebar (NERDTree + icons) | `Ctrl-b` / `Ctrl-n` / `F3` |
| Bottom terminal panel | `Ctrl-j` |
| Build (Makefile or `gcc`) | `Ctrl-e` |
| Run `./a.out` | `F6` |
| 42 header (insert/update) | `F1` |
| Norm auto-fix on save | `Space x` (deep fix) / `:NormAutoFixToggle` |
| git info in status line | automatic |
| `#include` helper | `Space i` / `Space I` |
| Autocomplete popup | `Tab` / `<C-n><C-p>` |
| Key cheat sheet | `Space ?` |

Icons come from **vim-devicons**; set your terminal font to a Nerd Font
(e.g. JetBrainsMono Nerd Font) for them to render.

## Deliberately removed (this is not an AI config)

- The Kitty launcher (`kitty -e vim`) — Vim opens in the current terminal.
- The agent panel (`<C-k>` / `F8`, Nataku, `Tapi_*`, compose box).
- All `agent` / `nataku` / `NVIDIA` / `claude` / `aider` / `codex` / `gemini` code.
- Markdown preview / review / quickfix agent tooling.

## Install

```sh
git clone https://github.com/mrcholer/vim.git
cd vim
chmod +x install.sh
./install.sh
```

This copies `vimrc` to `~/.vimrc`, installs vim-plug, and runs `PlugInstall`
to fetch NERDTree, vim-devicons and onedark.

## Files

- `vimrc` — the full Vim configuration (copy to `~/.vimrc`)
- `install.sh` — one-command installer
- `README.md` — this file
