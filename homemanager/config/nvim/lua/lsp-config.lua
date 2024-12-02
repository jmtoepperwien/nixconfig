-- UI stuff
local signs = { Error = "⚡", Warn = "⚠ ", Hint = "💡", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- to enable nvim-cmp (use in setup of lsps)
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local on_attach = function(client, bufnr) 
  require('navigator.lspclient.mapping').setup({ bufnr = bufnr, client = client })
  require "lsp_signature".on_attach({}, bufnr)
end

-- Python
require('lspconfig').pyright.setup { capabilities = capabilities, on_attach = on_attach, settings = {
    exclude = { ".venv" },
    venvPath = ".",
    venv = ".venv"
  } }

-- Lua
require'lspconfig'.lua_ls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if vim.uv.fs_stat(path..'/.luarc.json') or vim.uv.fs_stat(path..'/.luarc.jsonc') then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT'
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME
          -- Depending on the usage, you might want to add additional paths here.
          -- "${3rd}/luv/library"
          -- "${3rd}/busted/library",
        }
        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
        -- library = vim.api.nvim_get_runtime_file("", true)
      }
    })
  end,
  settings = {
    Lua = {}
  }
}

-- Haskell
require('lspconfig').hls.setup { capabilities = capabilities, on_attach = on_attach,
  filetypes = { 'haskell', 'lhaskell', 'cabal' } }

-- C/C++
require('lspconfig').clangd.setup { capabilities = capabilities, on_attach = on_attach, }
