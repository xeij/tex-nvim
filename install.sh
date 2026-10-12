#!/bin/sh
# Installs BasicTeX (macOS, via Homebrew) if no pdflatex is found, then installs
# every package a .tex file needs that the distribution is missing.
#
#   ./install.sh [file.tex ...]
#
# With no file, installs a few common resume/document packages.
set -e

if ! command -v brew >/dev/null; then
  echo "Homebrew is required: https://brew.sh" >&2; exit 1
fi

eval "$(/usr/libexec/path_helper)" 2>/dev/null || true
if ! command -v pdflatex >/dev/null; then
  echo "==> Installing BasicTeX (asks for your password)"
  brew install --cask basictex
  eval "$(/usr/libexec/path_helper)"
fi

echo "==> Updating tlmgr (asks for your password)"
sudo tlmgr update --self >/dev/null

# Package names the .sty files are *usually* missing from BasicTeX.
DEFAULT="preprint marvosym titlesec enumitem fontawesome5"

if [ $# -eq 0 ]; then
  pkgs=$DEFAULT
else
  pkgs=""
  # Every \usepackage{a,b} in the given files, one name per line, unique.
  for sty in $(grep -ohE '\\usepackage(\[[^]]*\])?\{[^}]*\}' "$@" | sed -E 's/.*\{([^}]*)\}/\1/' | tr ',' '\n' | tr -d ' ' | sort -u); do
    kpsewhich "$sty.sty" >/dev/null && continue
    # Map the .sty file to the TeX Live package that provides it.
    pkg=$(tlmgr search --global --file "/$sty.sty" 2>/dev/null | grep -m1 ':$' | tr -d ':')
    [ -n "$pkg" ] && pkgs="$pkgs $pkg" || echo "warn: no package provides $sty.sty" >&2
  done
fi

if [ -z "$pkgs" ]; then echo "==> Nothing missing"; exit 0; fi
echo "==> Installing:$pkgs"
sudo tlmgr install $pkgs
echo "==> Done. Restart nvim so it picks up the new PATH."
