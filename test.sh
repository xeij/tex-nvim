#!/bin/sh
# Runs the plugin headless against a fake compiler. Exit 0 = pass.
cd "$(dirname "$0")"
T=$(mktemp -d)
printf '\\documentclass{article}\\begin{document}hi\\end{document}\n' > "$T/a.tex"
cat > "$T/fake" <<'SH'
#!/bin/sh
case "$(cat "$1")" in *BAD*) echo "$1:1: Undefined control sequence."; exit 1;; esac
echo pdf > "${1%.tex}.pdf"
SH
chmod +x "$T/fake"
nvim --headless -u NONE --cmd "set rtp+=." -c "runtime plugin/tex.lua" "$T/a.tex" +"lua
  local tex = require('tex'); tex.setup({ cmd = { '$T/fake' } })
  local done = false
  tex.compile(function() done = true end)
  vim.wait(2000, function() return done end)
  assert(done, 'compile callback never fired')
  assert(vim.fn.filereadable('$T/a.pdf') == 1, 'pdf not produced')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'BAD' })
  tex.compile()
  vim.wait(2000, function() return #vim.fn.getqflist() > 0 end)
  local q = vim.fn.getqflist()
  assert(#q == 1 and q[1].lnum == 1 and q[1].text:match('Undefined'), 'error not in quickfix')
  print('ok')
  vim.cmd('qa!')" 2>&1
