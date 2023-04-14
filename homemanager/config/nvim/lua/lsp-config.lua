-- UI stuff
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- to enable nvim-cmp (use in setup of lsps)
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Python
require('lspconfig').pyright.setup { capabilities = capabilities,
  settings = {
    exclude = { ".venv" },
    venvPath = ".",
    venv = ".venv"
  } }

-- Lua
require('lspconfig').lua_ls.setup { capabilities = capabilities }

-- Haskell
require('lspconfig').hls.setup { capabilities = capabilities,
  filetypes = { 'haskell', 'lhaskell', 'cabal' } }

-- C/C++
require('lspconfig').clangd.setup {}
