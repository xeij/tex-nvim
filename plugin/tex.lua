local function tex() return require('tex') end

vim.api.nvim_create_user_command('TexCompile', function() tex().compile() end, {})
vim.api.nvim_create_user_command('TexOpen', function() tex().open() end, {})
vim.api.nvim_create_user_command('TexInstall', function() tex().install() end, {})

local group = vim.api.nvim_create_augroup('tex.nvim', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'tex',
  callback = function(ev)
    vim.keymap.set('n', '<leader>lc', '<cmd>TexCompile<CR>', { buffer = ev.buf, desc = 'Compile LaTeX' })
    vim.keymap.set('n', '<leader>lo', '<cmd>TexOpen<CR>', { buffer = ev.buf, desc = 'Open PDF' })
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  pattern = '*.tex',
  callback = function()
    if tex().config.on_save then tex().compile() end
  end,
})
