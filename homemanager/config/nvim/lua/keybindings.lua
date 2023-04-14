-- QoL bindings
vim.keymap.set("i", "kj", "<Esc>:noh<CR><Esc>")
vim.keymap.set("n", "<Esc>", "<Esc>:noh<CR><Esc>")
vim.keymap.set("n", "U", "<C-r>")
vim.keymap.set("n", "<leader>f", ":lua vim.lsp.buf.format()")

-- LSP
vim.keymap.set("n", "<Leader>rn", function() vim.lsp.buf.rename() end)

-- Telescope bindings
local builtin = require('telescope.builtin')
local project = require('telescope').extensions.project
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "<leader>fp", project.project, {})

-- Hop bindings
local hop = require('hop')
local directions = require('hop.hint').HintDirection
vim.keymap.set('', 'f', function()
  hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
end, { remap = true })
vim.keymap.set('', 'F', function()
  hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
end, { remap = true })
vim.keymap.set('', 't', function()
  hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
end, { remap = true })
vim.keymap.set('', 'T', function()
  hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
end, { remap = true })
vim.keymap.set('', '<leader>j', function()
  hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
end, { remap = true })
vim.keymap.set('', '<Leader>w', function() hop.hint_words() end, { remap = true })

-- Codeium
vim.keymap.set('i', '<C-g>', function() return vim.fn['codeium#Accept']() end, { expr = true })

-- Neogen bindings
vim.keymap.set("n", "<Leader>d", function() require('neogen').generate() end, { noremap = true, silent = true })
