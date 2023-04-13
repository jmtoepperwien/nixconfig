vim.opt.showmode = false

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

vim.cmd [[filetype plugin indent on]]
vim.opt.foldmethod = "indent"

vim.opt.ignorecase = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

vim.opt.updatetime = 100

vim.opt.hidden = true

vim.opt.termguicolors = true

-- enable loading of project specific configurations
vim.o.exrc = true
