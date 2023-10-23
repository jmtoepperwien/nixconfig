return require("lazy").setup({
  {
    "sainnhe/gruvbox-material",
    config = function()
      vim.g.gruvbox_material_better_performance = 1
      vim.cmd([[colorscheme gruvbox-material]])
    end,
    lazy = false,
    priority = 1000
  },
  { "equalsraf/neovim-gui-shim",   priority = 9999 },
  { 'nvim-tree/nvim-web-devicons', config = function() require('nvim-web-devicons').setup({ default = true }) end },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    config = function()
      require("lualine").setup({
        options = { theme = "gruvbox-material" },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
      ts_update()
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        auto_install = true,
        highlight = {
          enable = true
        },
        incremental_selection = {
          enable = true
        },
        indent = {
          enable = true
        },
        rainbow = {
          enable = true
        }
      })
      require("nvim-treesitter.install").compilers = { "gcc" } -- does not work with clang
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { { "nvim-lua/plenary.nvim" },
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      }, },
    config = function()
      require('telescope').setup({
        pickers = {
          find_files = {
            hidden = true,
            mappings = {
              n = {
                ["cd"] = function(prompt_bufnr)
                  local selection = require("telescope.actions.state").get_selected_entry()
                  local dir = vim.fn.fnamemodify(selection.path, ":p:h")
                  require("telescope.actions").close(prompt_bufnr)
                  -- Depending on what you want put `cd`, `lcd`, `tcd`
                  vim.cmd(string.format("silent lcd %s", dir))
                end
              }
            }
          },
        },
        extensions = {
          project = {
            --base_dirs = {
            --  '~/dev/src',
            --  { '~/dev/src2' },
            --  { '~/dev/src3',        max_depth = 4 },
            --  { path = '~/dev/src4' },
            --  { path = '~/dev/src5', max_depth = 2 },
            --},
            hidden_files = true, -- default: false
            theme = "dropdown",
            order_by = "asc",
            search_by = "title",
            sync_with_nvim_tree = true, -- default false
            on_project_selected = function(prompt_bufnr)
              local project_actions = require("telescope._extensions.project.actions")
              project_actions.change_working_directory(prompt_bufnr, false)

              -- ask if .nvim.lua should be loaded
              local localconf = io.open("./.nvim.lua", "r")
              if localconf ~= nil then
                local selection = vim.fn.input("Found .nvim.lua \nChoose action: [l]oad [i]gnore: ")
                if selection == "l" then
                  dofile("./.nvim.lua")
                end
              end
            end
          }
        }
      })
      require('telescope').load_extension('fzf')
    end
  },
  { "nvim-telescope/telescope-project.nvim", config = function() require('telescope').load_extension('project') end },
  {
    "HiPhish/rainbow-delimiters.nvim",
    dependencies = { "nvim-treesitter" },
    config = function()
      local rainbow_delimiters = require("rainbow-delimiters")
      require("rainbow-delimiters.setup").setup({
        strategy = {
          [''] = rainbow_delimiters.strategy['global'],
          vim = rainbow_delimiters.strategy['local'],
        },
        query = {
          [''] = 'rainbow-delimiters',
          lua = 'rainbow-blocks',
        },
        highlight = {
          'RainbowDelimiterRed',
          'RainbowDelimiterYellow',
          'RainbowDelimiterBlue',
          'RainbowDelimiterOrange',
          'RainbowDelimiterGreen',
          'RainbowDelimiterViolet',
          'RainbowDelimiterCyan',
        },
      })
    end,
  },
  { "lervag/vimtex",                         lazy = true },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- nvim-lsp setup {{{
  { 'neovim/nvim-lspconfig', config = function() require("lsp-config") end },

  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/cmp-nvim-lsp-signature-help",
  "hrsh7th/cmp-nvim-lua",
  { "onsails/lspkind-nvim" },
  { "L3MON4D3/LuaSnip" },
  "saadparwaiz1/cmp_luasnip",
  { "hrsh7th/nvim-cmp",      config = function() require('lsp-cmp-setup') end },
  -- nvim-lsp setup }}}

  {
    "ray-x/navigator.lua",
    dependencies = { { 'ray-x/guihua.lua', build = 'cd lua/fzy && make' }, { "neovim/nvim-lspconfig" } },
    config = function()
      require('navigator').setup({
        lsp = {
          disable_lsp = 'all', -- buggy with haskell, lsp-config.lua manually attaches navigator
          format_on_save = false,
        }
      })
    end
  },
  { "karb94/neoscroll.nvim", config = function() require('neoscroll').setup() end },
  {
    "danymat/neogen",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function() require('neogen').setup({ input_after_comment = true, jump_map = "<Tab>" }) end
  },
  {
    "echasnovski/mini.nvim",
    config = function()
      require('mini.align').setup()
      require('mini.comment').setup()
      require('mini.pairs').setup()
      require('mini.surround').setup()
    end
  },
  {
    "AckslD/nvim-neoclip.lua",
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('neoclip').setup();
      require('telescope').load_extension('neoclip')
    end
  },
  { "chentoast/marks.nvim",        config = function() require('marks').setup() end },
  { "norcalli/nvim-colorizer.lua", config = function() require('colorizer').setup() end },
  { "folke/twilight.nvim",         config = function() require("twilight").setup() end },
  { "kevinhwang91/nvim-bqf",       dependencies = { { "junegunn/fzf", build = function() vim.fn['fzf#install']() end } } },
  {
    "phaazon/hop.nvim",
    branch = "v2",
    config = function()
      require("hop").setup()
    end
  },
  { "rktjmp/highlight-current-n.nvim" },
  {
    "edluffy/specs.nvim",
    config = function()
      require("specs").setup {
        show_jumps       = true,
        min_jump         = 30,
        popup            = {
          delay_ms = 0, -- delay before popup displays
          inc_ms = 10,  -- time increments used for fade/resize effects
          blend = 10,   -- starting blend, between 0-100 (fully transparent), see :h winblend
          width = 10,
          winhl = "PMenu",
          fader = require('specs').linear_fader,
          resizer = require('specs').shrink_resizer
        },
        ignore_filetypes = {},
        ignore_buftypes  = {
          nofile = true,
        },
      }
    end
  },
  { 'Aasim-A/scrollEOF.nvim',         config = function() require('scrollEOF').setup() end },
  { 'tpope/vim-eunuch' },

  { 'figsoda/nix-develop.nvim' },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  },
  --{ "Exafunction/codeium.vim" }

  -- # Jupyter Notebooks in Neovim {{{
  {
    "goerz/jupytext.vim",
    config = function()
      vim.g.jupytext_fmt = "py:percent"
    end
  },
  {
    "dccsillag/magma-nvim",
    build = ":UpdateRemotePlugins",
    config = function()
      vim.g.magma_automatically_open_output = false
      vim.g.magma_image_provider = "ueberzug"
    end
  },
  { "GCBallesteros/vim-textobj-hydrogen", dependencies = { { 'kana/vim-textobj-user' } } },
  { "untitled-ai/jupyter_ascending.vim" },
  -- }}} Jupyter Notebooks in Neovim

})
