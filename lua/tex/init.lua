local M = {}

M.config = {
  cmd = { 'pdflatex', '-interaction=nonstopmode', '-halt-on-error', '-file-line-error' },
  open_cmd = { 'open' }, -- macOS; use { 'xdg-open' } on Linux
  on_save = false,       -- recompile on every :w
}

local running = false

local function tex_file()
  local f = vim.api.nvim_buf_get_name(0)
  if not f:match('%.tex$') then
    vim.notify('tex.nvim: not a .tex buffer', vim.log.levels.WARN)
    return nil
  end
  return f
end

local function pdf_of(tex) return (tex:gsub('%.tex$', '.pdf')) end

function M.compile(on_done)
  local tex = tex_file()
  if not tex or running then return end
  running = true
  vim.cmd('silent update')
  local cmd = vim.list_extend(vim.deepcopy(M.config.cmd), { tex })
  vim.system(cmd, { cwd = vim.fs.dirname(tex), text = true }, vim.schedule_wrap(function(r)
    running = false
    if r.code == 0 then
      vim.fn.setqflist({}, 'r')
      vim.cmd('cclose')
      vim.notify('tex.nvim: built ' .. vim.fs.basename(pdf_of(tex)))
      if on_done then on_done() end
    else
      -- -file-line-error makes pdflatex print "<file>:<line>: <msg>"; drop everything else.
      vim.fn.setqflist({}, 'r', { title = 'tex', lines = vim.split(r.stdout or '', '\n'), efm = '%f:%l: %m,%-G%.%#' })
      vim.cmd('copen')
    end
  end))
end

function M.open()
  local tex = tex_file()
  if not tex then return end
  local pdf = pdf_of(tex)
  if vim.fn.filereadable(pdf) == 0 then return M.compile(M.open) end
  vim.system(vim.list_extend(vim.deepcopy(M.config.open_cmd), { pdf }))
end

-- Runs install.sh for the current file in a terminal split (sudo needs a tty).
function M.install()
  local tex = tex_file()
  if not tex then return end
  local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p'))))
  vim.cmd('split | terminal ' .. vim.fn.shellescape(root .. '/install.sh') .. ' ' .. vim.fn.shellescape(tex))
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
