# tex.nvim

A small Neovim plugin that compiles the current LaTeX file and opens the resulting PDF, without leaving the editor. Compile errors land in the quickfix list with the right file and line. It targets single-file documents such as a resume, a letter, or a short paper, and it can set up a working TeX install on a fresh Mac in one command.

Lua, Neovim 0.10 or newer, any TeX engine on `$PATH`. The installer uses Homebrew and is macOS only; the plugin itself runs anywhere.

## Install

With lazy.nvim, add the plugin spec and restart Neovim:

```lua
{ 'xeij/tex-nvim', ft = 'tex', opts = {} }
```

For a local clone, use `dir = '/path/to/tex.nvim'` instead of the first string.

Options and their defaults:

```lua
opts = {
  cmd = { 'pdflatex', '-interaction=nonstopmode', '-halt-on-error', '-file-line-error' },
  open_cmd = { 'open' },   -- { 'xdg-open' } on Linux
  on_save = false,         -- recompile on every :w
}
```

## First run

Open any `.tex` file and run `:TexInstall`. It opens a terminal split and runs `install.sh`, which:

1. installs BasicTeX through Homebrew if there is no `pdflatex`,
2. updates the TeX Live package manager,
3. installs every package the open file uses that the distribution lacks.

It asks for a password because TeX Live installs system-wide. Restart Neovim afterwards so it picks up the new `$PATH`.

The same script works from a shell:

```
./install.sh                # BasicTeX plus a set of common document packages
./install.sh document.tex   # only the packages this file needs
```

BasicTeX is deliberately small, about 100 MB, so a new document may hit a package it does not have. If a compile fails with `File 'x.sty' not found`, run `:TexInstall` again.

## Usage

In a `.tex` buffer:

| Key          | Command       | Effect                                       |
| ------------ | ------------- | -------------------------------------------- |
| `<leader>lc` | `:TexCompile` | Save and compile                             |
| `<leader>lo` | `:TexOpen`    | Open the PDF, compiling first if missing     |
|              | `:TexInstall` | Install TeX and the packages this file needs |

`<leader>` is the space bar by default in many configurations; check `vim.g.mapleader` if unsure. Setting `on_save = true` rebuilds the PDF on every write, and most PDF viewers reload the file in place.

## How it works

`compile` runs the engine asynchronously with `vim.system` in the file's directory, so the editor stays responsive. The `-file-line-error` flag makes pdflatex print errors as `file:line: message`, which a two-rule errorformat parses: one rule captures those lines, the other discards everything else. A successful build clears and closes quickfix; a failed one opens it.

`install.sh` reads every `\usepackage` in the file, checks each with `kpsewhich`, and maps the missing `.sty` files to TeX Live package names with `tlmgr search --file`. The two often differ, which is why a plain `tlmgr install fullpage` fails: `fullpage.sty` lives in a package called `preprint`.

A single `running` flag prevents overlapping builds, which also stops `on_save` from double-compiling when a manual compile triggers a write.

## Testing

```
./test.sh
```

Runs Neovim headless with a fake compiler, so it passes without a TeX install. It checks that a good build produces the PDF and fires the callback, and that a failing build puts the error in quickfix at the right line.

## Limitations

Single-file documents only. No bibliography pass, no SyncTeX, no continuous preview. For those, use vimtex.
