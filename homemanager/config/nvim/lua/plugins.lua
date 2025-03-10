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
    'nmac427/guess-indent.nvim',
    config = function()
      require('guess-indent').setup {
        auto_cmd = true,               -- Set to false to disable automatic execution
        override_editorconfig = false, -- Set to true to override settings set by .editorconfig
        filetype_exclude = {           -- A list of filetypes for which the auto command gets disabled
          "netrw",
          "tutor",
        },
        buftype_exclude = { -- A list of buffer types for which the auto command gets disabled
          "help",
          "nofile",
          "terminal",
          "prompt",
        },
        on_tab_options = { -- A table of vim options when tabs are detected
          ["expandtab"] = false,
          ["tabstop"] = 2, -- If the option value is 'detected', The value is set to the automatically detected indent size.
          ["softtabstop"] = 2,
          ["shiftwidth"] = 2,
        },
        on_space_options = {        -- A table of vim options when spaces are detected
          ["expandtab"] = true,
          ["tabstop"] = "detected", -- If the option value is 'detected', The value is set to the automatically detected indent size.
          ["softtabstop"] = "detected",
          ["shiftwidth"] = "detected",
        },
      }
    end,
  },
  { "tpope/vim-sensible" },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { { "nvim-lua/plenary.nvim" },
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make'
      }, },
    config = function()
      vim.api.nvim_create_autocmd("FileType", { pattern = "TelescopeResults", command = "setlocal nofoldenable", })
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
  { "lervag/vimtex",         lazy = true },
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
  { "L3MON4D3/LuaSnip",    version = "v2.*", build = "make install_jsregexp" },
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
    lazy = true,
    event = "CursorHold",
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
  { "danilamihailov/beacon.nvim" },
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
  -- # Jupyter Notebooks in Neovim {{{
  {
    "GCBallesteros/jupytext.nvim",
    enabled = true,
    config = function()
      require("jupytext").setup({
        style = "markdown",
        output_extension = "md",
        force_ft = "markdown",
      })
    end
  },
  {
    "dccsillag/magma-nvim",
    enabled = false,
    build = ":UpdateRemotePlugins",
    config = function()
      vim.g.magma_automatically_open_output = false
      vim.g.magma_image_provider = "ueberzug"
    end
  },
  { "GCBallesteros/vim-textobj-hydrogen", dependencies = { { 'kana/vim-textobj-user' } } },
  { "untitled-ai/jupyter_ascending.vim" },
  -- }}} Jupyter Notebooks in Neovim

  {
    'nvim-focus/focus.nvim',
    version = false,
    config = function()
      require("focus").setup()
    end
  },
  {
    "epwalsh/obsidian.nvim",
    lazy = true,
    event = "CursorHold",
    version = "*", -- recommended, use latest release instead of latest commit
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      ui = { enable = false },
      workspaces = {
        {
          name = "personal",
          path = "~/vaults/personal",
        },
      },
      daily_notes = {
        folder = "daily_notes",
      },
      -- Optional, customize how note file names are generated given the ID, target directory, and title.
      ---@param spec { id: string, dir: obsidian.Path, title: string|? }
      ---@return string|obsidian.Path The full path to the new note.
      note_path_func = function(spec)
        -- This is equivalent to the default behavior.
        local path = spec.dir / spec.title
        return path:with_suffix(".md")
      end,
      -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
      completion = {
        -- Set to false to disable completion.
        nvim_cmp = true,
        -- Trigger completion at 2 chars.
        min_chars = 2,
      },
      -- Where to put new notes. Valid options are
      --  * "current_dir" - put new notes in same directory as the current buffer.
      --  * "notes_subdir" - put new notes in the default notes subdirectory.
      new_notes_location = "current_dir",
      wiki_link_func = "prepend_note_path",
      -- Optional, sort search results by "path", "modified", "accessed", or "created".
      -- The recommend value is "modified" and `true` for `sort_reversed`, which means, for example,
      -- that `:ObsidianQuickSwitch` will show the notes sorted by latest modified time
      sort_by = "modified",
      sort_reversed = true,
    },
  },
  {
    "tris203/hawtkeys.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = {
      leader = ",",
      keyboardLayout = "qwerty",
      ["wk.register"] = {
        method = "which_key",
      },
      ["lazy"] = {
        method = "lazy",
      },
    },
  },
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {
      -- configurations go here
    },
    config = function()
      -- triggers CursorHold event faster
      vim.opt.updatetime = 200

      require("barbecue").setup({
        create_autocmd = false, -- prevent barbecue from updating itself automatically
      })

      vim.api.nvim_create_autocmd({
        "WinScrolled", -- or WinResized on NVIM-v0.9 and higher
        "BufWinEnter",
        "CursorHold",
        "InsertLeave",

        -- include this if you have set `show_modified` to `true`
        "BufModifiedSet",
      }, {
        group = vim.api.nvim_create_augroup("barbecue.updater", {}),
        callback = function()
          require("barbecue.ui").update()
        end,
      })
    end,
  },
  {
    "amitds1997/remote-nvim.nvim",
    version = "*",                     -- Pin to GitHub releases
    dependencies = {
      "nvim-lua/plenary.nvim",         -- For standard functions
      "MunifTanjim/nui.nvim",          -- To build the plugin UI
      "nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
    },
    config = function()
      require("remote-nvim").setup({
        -- Offline mode configuration. For more details, see the "Offline mode" section below.
        offline_mode = {
          -- Should offline mode be enabled?
          enabled = true,
          -- Do not connect to GitHub at all. Not even to get release information.
          no_github = false,
        },
      })
    end,
  }, {
  "3rd/image.nvim",
  opts = {},
  lazy = true,
  event = "CursorHold",
  config = function()
    require("image").setup(
    -- image nvim options table. Pass to `require('image').setup`
      {
        backend = "kitty",                        -- Kitty will provide the best experience, but you need a compatible terminal
        integrations = {},                        -- do whatever you want with image.nvim's integrations
        max_width = 100,                          -- tweak to preference
        max_height = 12,                          -- ^
        max_height_window_percentage = math.huge, -- this is necessary for a good experience
        max_width_window_percentage = math.huge,
        window_overlap_clear_enabled = true,
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      })
  end,
},
  {
    "benlubas/molten-nvim",
    lazy = true,
    ft = { "markdown", "quarto", "rmd" },
    version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      -- this guide will be using image.nvim
      -- Don't forget to setup and install the plugin if you want to view image outputs
      vim.g.molten_image_provider = "image.nvim"

      -- optional, I like wrapping. works for virt text and the output window
      vim.g.molten_wrap_output = true

      -- Output as virtual text. Allows outputs to always be shown, works with images, but can
      -- be buggy with longer images
      vim.g.molten_virt_text_output = true

      -- this will make it so the output shows up below the \`\`\` cell delimiter
      vim.g.molten_virt_lines_off_by_1 = true
    end,
  },
  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("quarto").setup({
        lspFeatures = {
          -- NOTE: put whatever languages you want here:
          languages = { "r", "python", "rust", "html" },
          chunks = "all",
          diagnostics = {
            enabled = true,
            triggers = { "BufWritePost" },
          },
          completion = {
            enabled = true,
          },
        },
        keymap = {
          -- NOTE: setup your own keymaps:
          hover = "H",
          definition = "gd",
          rename = "<leader>rn",
          references = "gr",
          format = "<leader>gf",
        },
        codeRunner = {
          enabled = true,
          default_method = "molten",
        },
      })
    end,
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = { doc_lines = 30 },
    config = function(_, opts) require 'lsp_signature'.setup(opts) end
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",  -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua",              -- optional
      "echasnovski/mini.pick",         -- optional
    },
    config = true
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  },
  {
    -- This is a fork of the original pretty-fold.nvim. No indication if this will be further supported.
    "bbjornstad/pretty-fold.nvim",
    config = function()
      require("pretty-fold").setup()
    end,
  },
}, {
  rocks = {
    hererocks = false, -- recommended if you do not have global installation of Lua 5.1.
  },
})
