# tex.nvim

A small Neovim plugin that compiles the current LaTeX buffer and opens the resulting PDF, without leaving the editor. Compile errors land in the quickfix list with the right file and line.

Lua, Neovim 0.10+ (`vim.system`), any TeX engine on `$PATH`.

## Setup

With lazy.nvim:

```lua
{ dir = '~/Desktop/tex.nvim', ft = 'tex', opts = {} }
```

Options and their defaults:

```lua
opts = {
  cmd = { 'pdflatex', '-interaction=nonstopmode', '-halt-on-error', '-file-line-error' },
  open_cmd = { 'open' },   -- { 'xdg-open' } on Linux
  on_save = false,         -- recompile on every :w
}
```

Then open any `.tex` file and run `:TexInstall`. It opens a terminal split and runs `install.sh`, which installs BasicTeX through Homebrew if there is no `pdflatex`, then installs every package the file uses that the distribution lacks. It asks for a password because TeX Live installs system-wide. The same script runs from a shell:

```
./install.sh            # BasicTeX plus common document packages
./install.sh resume.tex # only what this file needs
```

BasicTeX is deliberately small (about 100 MB), so a new document can hit a missing package. If compiling fails with `File 'x.sty' not found`, run `:TexInstall` again.

## Usage

In a `.tex` buffer:

| Key          | Command       | Effect                                       |
| ------------ | ------------- | -------------------------------------------- |
| `<leader>lc` | `:TexCompile` | Save and compile                             |
| `<leader>lo` | `:TexOpen`    | Open the PDF, compiling first if missing     |
|              | `:TexInstall` | Install TeX and the packages this file needs |

## How it works

`compile` runs the engine asynchronously with `vim.system` in the file's directory, so the editor stays responsive. The `-file-line-error` flag makes pdflatex print errors as `file:line: message`, which is parsed with a two-rule errorformat: one to capture those lines, one to discard everything else. A successful build clears and closes quickfix; a failed one opens it.

`install.sh` reads every `\usepackage` from the file, checks each with `kpsewhich`, and maps the missing `.sty` files to TeX Live package names with `tlmgr search --file`, since the two often differ (`fullpage.sty` lives in `preprint`).

A single `running` flag prevents overlapping builds, which also stops `on_save` from double-compiling when a manual compile triggers a write.

## Testing

```
./test.sh
```

Runs Neovim headless with a fake compiler script, so it passes without a TeX install. It checks that a good build produces the PDF and fires the callback, and that a failing build puts the error in quickfix at the right line.

## Limitations

Single-file documents only. No bibliography pass, no SyncTeX, no continuous preview. For those, use vimtex.
