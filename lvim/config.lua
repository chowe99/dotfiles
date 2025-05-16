-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny


-- General Vim Settings
vim.g.mapleader = " "
vim.g.python3_host_prog = "~/.pyenv/shims/python"

vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.hlsearch = true
vim.opt.backup = false
vim.opt.showcmd = true
vim.opt.cmdheight = 0
vim.opt.laststatus = 0
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.wrap = false
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "cursor"
vim.opt.mouse = ""

-- Add asterisks in block comments
vim.opt.formatoptions:append({ "r" })

-- Disable default NvimTree
lvim.builtin.nvimtree.active = false

-- Enable automatic installation of servers
lvim.lsp.installer.setup.automatic_installation = true

-- Language Servers
lvim.lsp.installer.setup.ensure_installed = {
  "lua_ls",
  "tsserver",    -- JavaScript/TypeScript
  "pyright",     -- Python
  "tailwindcss", -- Tailwind CSS
  "html",        -- HTML
  "cssls",       -- CSS
  "jsonls",      -- JSON
  "yamlls",      -- YAML
  "dockerls",    -- Dockerfile
  "graphql",     -- GraphQL
  "bashls",      -- Bash
  "eslint",
  "emmet_ls",
  "clangd", -- C/C++
  -- Add other servers if needed
}

-- Formatter setup
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  -- For JavaScript/TypeScript
  {
    command = "prettierd",
    filetypes = { "javascript", "typescript", "typescriptreact", "javascriptreact", "vue", "html", "css", "json", "yaml" },
  },
  -- For Python
  {
    command = "black",
    filetypes = { "python" },
  },
  -- Add any other formatters you need
  {
    command = "stylelint",
    filetypes = { "css", "scss", "sass", "less" },
  },
  {
    command = "shfmt",
    filetypes = { "sh", "bash" },
  },
}
-- Linter setup
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  -- For JavaScript/TypeScript
  {
    command = "eslint_d",
    filetypes = { "javascript", "typescript", "typescriptreact", "javascriptreact", "vue" },
  },

  -- For Python
  {
    command = "pylint",
    filetypes = { "python" },
  },
  -- Add any other linters you need
  {
    command = "stylelint",
    filetypes = { "css", "scss", "sass", "less" },
  },
  {
    command = "shellcheck",
    filetypes = { "sh", "bash" },
  },
}

local lsp_manager = require("lvim.lsp.manager")

-- Configure Tailwind CSS LSP with proper on_attach
lsp_manager.setup("tailwindcss", {
  on_attach = function(client, bufnr)
    -- Call the common on_attach function
    require("lvim.lsp").common_on_attach(client, bufnr)
    -- Removed tailwind-highlight setup
  end,
})

-- Configure HTML LSP
lsp_manager.setup("html", {
  on_attach = function(client, bufnr)
    -- Call the common on_attach function
    require("lvim.lsp").common_on_attach(client, bufnr)

    -- Optional: Add any HTML-specific configurations here
  end,
})

-- Set up the Lua language server
lsp_manager.setup("lua_ls", {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using
        version = "LuaJIT",
        -- Setup your Lua path
        path = vim.split(package.path, ";"),
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` and `lvim` globals
        globals = { "vim", "lvim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        -- Adjust these two settings if you encounter performance issues with large projects
        maxPreload = 1000,
        preloadFileSize = 1000,
      },
      telemetry = {
        enable = false, -- Do not send telemetry data containing a unique identifier
      },
    },
  },
})

local lspconfig = require('lspconfig')

-- Configure tsserver with formatting disabled
lspconfig.tsserver.setup {
  on_attach = function(client, bufnr)
    -- Disable tsserver formatting if you use prettier
    client.server_capabilities.documentFormattingProvider = false
    require('lvim.lsp').common_on_attach(client, bufnr)
  end,
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  settings = {
    typescript = {
      jsx = true,
    },
    javascript = {
      jsx = true,
    },
  },
}
-- Configure pyright for Python
lspconfig.pyright.setup {
  on_attach = require('lvim.lsp').common_on_attach,
}


lspconfig.emmet_ls.setup {
  filetypes = { "html", "css", "javascript", "javascriptreact", "typescriptreact" },
  init_options = {
    html = {
      options = {
        -- For JSX compatibility
        ["jsx.enabled"] = true,
      },
    },
  },
}

-- Plugins Configuration
lvim.plugins = {
  { "mbbill/undotree" },
  -- {
  --   "tpope/vim-fugitive",
  --   cmd = { "Git", "G" },
  --   config = function()
  --     -- Optional: Custom keybindings
  --     lvim.builtin.which_key.mappings["g"] = {
  --       name = "Git",
  --       s = { "<cmd>Git<CR>", "Status" },
  --       c = { "<cmd>Git commit<CR>", "Commit" },
  --       p = { "<cmd>Git push<CR>", "Push" },
  --       l = { "<cmd>Git log<CR>", "Log" },
  --       d = { "<cmd>Gdiffsplit<CR>", "Diff" },
  --     }
  --   end,
  -- },
  -- {
  --   "edluffy/hologram.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     require('hologram').setup {
  --       auto_display = true, -- Automatically display images in markdown files
  --     }
  --   end,
  -- },
  { "nvim-pack/nvim-spectre" }, -- Needs gnu-sed on MacOS (brew install gnu-sed)
  {
    'cameron-wags/rainbow_csv.nvim',
    ft = {
      'csv',
      'tsv',
      'csv_semicolon',
      'csv_whitespace',
      'csv_pipe',
      'rfc_csv',
      'rfc_semicolon'
    },
    cmd = {
      'RainbowDelim',
      'RainbowDelimSimple',
      'RainbowDelimQuoted',
      'RainbowMultiDelim'
    },
    config = function()
      -- Load the plugin
      require("rainbow_csv").setup()

      -- Auto-align CSV files on BufWinEnter
      vim.api.nvim_create_autocmd("BufWinEnter", {
        pattern = {
          "*.csv",
          "*.tsv",
          "*.csv_semicolon",
          "*.csv_whitespace",
          "*.csv_pipe",
          "*.rfc_csv",
          "*.rfc_semicolon"
        },
        callback = function()
          vim.cmd("RainbowAlign")
        end,
      })
    end,
  },
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "BufRead",
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- Set this if you want to always pull the latest changes
    opts = {
      use_absolute_path = true,
      tokenizer = "tiktoken",
      -- provider = "ollama",                           -- switched provider to local ollama
      -- ollama = {
      --   endpoint = "http://127.0.0.1:11434",         -- Note that there is no /v1 at the end.
      --   model = "qwen2.5-coder:32b-instruct-q4_K_M", -- change to your desired model if necessary
      -- },
      -- provider = "claude",
      -- claude = {
      --   endpoint = "https://api.anthropic.com",
      --   model = "claude-3-5-sonnet-20241022",
      --   temperature = 0,
      --   max_tokens = 8000,
      --   timeout = 30000, -- Timeout in milliseconds
      -- },
      -- provider = "openai",
      -- openai = {
      --   endpoint = "https://api.openai.com/v1",
      --   model = "o3-mini",
      --   temperature = 0,
      --   -- max_tokens = 8000,
      --   timeout = 30000, -- Timeout in milliseconds
      --   -- disable_tools = true,
      -- },
      provider = "gemini",
      gemini = {
        -- model = "gemini-2.5-pro-exp-03-25", -- or "gemini-pro-vision" if you need image capabilities
        model = "gemini-2.5-flash-preview-04-17",
        temperature = 0,
        -- max_tokens = 8000,
        -- disable_tools = true,
        timeout = 30000, -- Timeout in milliseconds
      },

      behaviour = {
        auto_suggestions = false, -- Experimental stage
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
      },
      mappings = {
        --- @class AvanteConflictMappings
        diff = {
          ours = 'co',
          theirs = 'ct',
          all_theirs = '<C-a>',
          both = 'cb',
          cursor = 'cc',
          next = ']x',
          prev = '[x',
        },
        suggestion = {
          accept = '<M-l>',
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
        jump = {
          next = ']]',
          prev = '[[',
        },
        submit = {
          normal = '<CR>',
          insert = '<C-s>',
        },
      },
      hints = { enabled = true },
      windows = {
        ---@type "right" | "left" | "top" | "bottom"
        position = 'bottom', -- The position of the sidebar
        wrap = true,         -- Similar to vim.o.wrap
        width = 100,         -- Default % based on available width
        sidebar_header = {
          align = 'center',  -- Align title to left, center, or right
          rounded = true,
        },
      },
      highlights = {
        ---@type AvanteConflictHighlights
        diff = {
          current = 'DiffText',
          incoming = 'DiffAdd',
        },
      },
      --- @class AvanteConflictUserConfig
      diff = {
        autojump = true,
        ---@type string | fun(): any
        list_opener = 'copen',
      },
    },
    -- If you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make BUILD_FROM_SOURCE=true",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- For Windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional
      "nvim-tree/nvim-web-devicons", -- Or echasnovski/mini.icons
      {
        -- Support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("avante.api").ask()
        end,
        desc = "avante: ask",
        mode = { "n", "v" },
      },
      {
        "<leader>ar",
        function()
          require("avante.api").refresh()
        end,
        desc = "avante: refresh",
      },
      {
        "<leader>ae",
        function()
          require("avante.api").edit()
        end,
        desc = "avante: edit",
        mode = "v",
      },
    },
  },

  {
    "github/copilot.vim",
    config = function()
      vim.g.copilot_no_tab_map = true

      -- Accept the current suggestion with <Right>
      vim.api.nvim_set_keymap("i", "<Right>", 'copilot#Accept("<CR>")', { expr = true, silent = true })

      -- Cycle to the next suggestion with <Left>
      vim.api.nvim_set_keymap("i", "<Left>", 'copilot#Next()', { expr = true, silent = true })
    end,
  },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require('toggleterm').setup {
        size = 20,
        open_mapping = [[<c-\>]],
        shading_factor = 2,
        direction = 'float',
        float_opts = {
          border = 'curved',
        },
      }
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require('nvim-autopairs').setup {}
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    config = function()
      require('nvim-ts-autotag').setup {}
    end,
  },
  {
    "rcarriga/nvim-notify",
    opts = function()
      return {
        background_colour = "#000000",
      }
    end,

  },
  -- messages, cmdline and the popupmenu
  {
    "folke/noice.nvim",
    opts = function()
      local opts = {}
      opts.routes = {}

      -- Skip "No information available" notifications
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })

      -- If not focused, use a desktop notification view
      local focused = true
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function() focused = true end,
      })
      vim.api.nvim_create_autocmd("FocusLost", {
        callback = function() focused = false end,
      })

      table.insert(opts.routes, 1, {
        filter = {
          cond = function() return not focused end,
        },
        view = "notify_send",
        opts = { stop = false },
      })

      -- *** NEW ROUTE: All msg_show events are routed as notify popups ***
      table.insert(opts.routes, 1, {
        filter = { event = "msg_show" },
        view = "notify",
        opts = { timeout = 1000, replace = true },
      })

      opts.commands = {
        all = {
          view = "split",
          opts = { enter = true, format = "details" },
          filter = {},
        },
      }

      opts.notify = {
        enabled = true,
        view = "notify",
      }

      opts.presets = {
        lsp_doc_border = true,
      }

      opts.views = {
        popup = {
          relative = "editor",
          position = { row = "50%", col = "50%" },
          size = { height = 5, width = 50 },
          enter = false,
        },
        -- Custom notify view using nvim-notify's backend
        notify = {
          backend = "notify",
          timeout = 1000,
          background_colour = "#000000",
          render = "compact",
          max_visible = 1,
        },
      }
      return opts
    end,
  },

  -- buffer line
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<Tab>",   "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },
  -- Highlight colors
  {
    "echasnovski/mini.hipatterns",
    event = "BufReadPre",
    opts = {},
  },

  -- null-ls for lsps
  { "jose-elias-alvarez/null-ls.nvim" },

  -- React and JavaScript snippets
  {
    "dsznajder/vscode-es7-javascript-react-snippets",
    build = "yarn install --frozen-lockfile && yarn compile",
  },

  -- Tailwind CSS highlighting
  {
    "roobert/tailwindcss-colorizer-cmp.nvim",
    lazy = true,
    event = "LspAttach",
    config = function()
      require("tailwindcss-colorizer-cmp").setup()
    end,
  },
  -- Neo-tree configuration
  {
    "nvim-neo-tree/neo-tree.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- Optional, for icons
      "MunifTanjim/nui.nvim",
      { "edluffy/hologram.nvim" },   -- Add hologram.nvim as a dependency
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          window = {
            position = "right", -- Neo-tree on the right side
            width = 25,         -- Set the width of the Neo-tree window
            mapping_options = {
              noremap = true,
              nowait = true,
            },
            mappings = {
              ["<leader>p"] = "image_preview", -- Map <leader>p to trigger image preview
            },
          },
          commands = {
            image_preview = function(state)
              local node = state.tree:get_node()
              if node.type == "file" then
                local hologram = require("hologram")
                hologram.setup {
                  auto_display = false, -- Disable auto display for manual triggering
                }
                -- Create a floating window for image preview
                local buf = vim.api.nvim_create_buf(false, true) -- Create a scratch buffer
                local width = vim.o.columns * 0.5                -- Adjust width to 50% of the screen
                local height = vim.o.lines * 0.5                 -- Adjust height to 50% of the screen
                vim.api.nvim_open_win(buf, true, {               -- Open the floating window
                  relative = "editor",
                  width = math.floor(width),
                  height = math.floor(height),
                  row = math.floor((vim.o.lines - height) / 2), -- Center the window
                  col = math.floor((vim.o.columns - width) / 2),
                  style = "minimal",
                  border = "rounded",
                })
                -- Display the image
                require('hologram.image'):new(node.path):display(1, 1, buf, {}) -- Start at line 1, column 1
              else
                vim.notify("Not a valid image file!", vim.log.levels.WARN)
              end
            end,
          },
        },
      })
    end,
  },
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    opts = {
      -- table: default groups
      groups = {
        "Normal",
        "NormalNC",
        "Comment",
        "Constant",
        "Special",
        "Identifier",
        "Statement",
        "PreProc",
        "Type",
        "Underlined",
        "Todo",
        "String",
        "Function",
        "Conditional",
        "Repeat",
        "Operator",
        "Structure",
        "LineNr",
        "NonText",
        "SignColumn",
        "CursorLineNr",
        "EndOfBuffer",
        "FloatBorder",
      },
      -- table: additional groups that should be cleared
      extra_groups = {
        "NormalFloat",
        "NeoTreeNormal",
        "NeoTreeNormalNC",
        "NeoTreeNormalFloat",
        "NeoTreeEndOfBuffer",
      },
      -- table: groups you don't want to clear
      exclude_groups = {},
    }
  },
}

-- ======================================
-- Treesitter Configuration
-- ======================================
lvim.builtin.treesitter.ensure_installed = {
  "javascript",
  "typescript",
  "tsx", -- For React JSX
  "python",
  "html",
  "css",
  "json",
  "yaml",
  "gitignore",
  "graphql",
  "http",
  "scss",
  "sql",
  "vim",
  "lua",
}

lvim.builtin.treesitter.highlight.enable = true
lvim.builtin.treesitter.highlight.disable = { "csv" }
lvim.builtin.treesitter.ignore_install = { "csv" }

-- Treesitter folding setup
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldenable = false
vim.o.foldlevel = 0
vim.o.foldlevelstart = 0

-- Autocmd to fold all on open
-- vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost" }, {
--   pattern = "*",
--   callback = function()
--     if not vim.b.folds_initialized then
--       vim.cmd("normal! zM") -- Collapse all folds (just once)
--       vim.b.folds_initialized = true
--     end
--   end
-- })
--

-- Toggle all folds (zM / zR)
function ToggleAllFolds()
  if vim.b.folds_collapsed == nil then
    vim.b.folds_collapsed = true
  end
  if vim.b.folds_collapsed then
    vim.cmd("normal! zR") -- Open all
  else
    vim.cmd("normal! zM") -- Collapse all
  end
  vim.b.folds_collapsed = not vim.b.folds_collapsed
end

-- Toggle current fold open/closed
function ToggleCurrentFold()
  local line = vim.fn.line(".")
  if vim.fn.foldclosed(line) == -1 then
    vim.cmd("normal! zc") -- Collapse
  else
    vim.cmd("normal! zo") -- Expand
  end
end

-- Key mappings
vim.keymap.set("n", "<leader>oa", ToggleAllFolds, { desc = "Toggle All Folds" })
vim.keymap.set("n", "<leader>oo", ToggleCurrentFold, { desc = "Toggle Current Fold" })

-- which-key bindings
lvim.builtin.which_key.mappings["o"] = {
  name = "Folds",
  a = { "<cmd>lua ToggleAllFolds()<CR>", "Toggle All Folds" },
  o = { "<cmd>lua ToggleCurrentFold()<CR>", "Toggle Current Fold" },
}



-- Additional Treesitter configurations
require('nvim-treesitter.configs').setup {
  ensure_installed = lvim.builtin.treesitter.ensure_installed,
  highlight = {
    enable = lvim.builtin.treesitter.highlight.enable,
  },
  autotag = {
    enable = true,
  },
  query_linter = {
    enable = true,
    use_virtual_text = true,
    lint_events = { "BufWrite", "CursorHold" },
  },
}

-- Enable format on save
lvim.format_on_save = true

-- DAP setup
local dap = require('dap')

dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = { vim.fn.stdpath('data') .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
}

dap.configurations.javascript = {
  {
    name = 'Launch',
    type = 'node2',
    request = 'launch',
    program = '${file}',
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = 'inspector',
  },
}

-- Keybindings
lvim.keys.normal_mode['<leader>sf'] = require('telescope.builtin').find_files
lvim.keys.normal_mode['<leader>sg'] = require('telescope.builtin').live_grep
lvim.keys.normal_mode['<C-t>'] = ":Neotree toggle<CR>"
lvim.keys.normal_mode["x"] = '"_x'
lvim.keys.visual_mode["d"] = '"_d'

lvim.builtin.which_key.mappings['e'] = {}
-- Error mappings in normal mode
lvim.keys.normal_mode["<leader>ee"] = vim.diagnostic.open_float
lvim.keys.normal_mode["<leader>ed"] = "<cmd>Telescope diagnostics<CR>"
-- Mapping for Noice all on <leader>eh
lvim.keys.normal_mode["<leader>eh"] = "<cmd>Noice all<CR>"

-- which_key group for error/diagnostic related commands under <leader>e
lvim.builtin.which_key.mappings["e"] = {
  name = "Diagnostics",
  e = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Open Error Float" },
  d = { "<cmd>Telescope diagnostics<CR>", "Error Diagnostics" },
  h = { "<cmd>Noice all<CR>", "Noice All" },
}

-- Map ToggleTerm commands to open specific terminals
lvim.builtin.which_key.mappings['t'] = { -- Removed <leader> since which_key already uses <leader>
  group = "terminals",
  name = "Terminals",
  desc = "Terminal commands",
  ['1'] = { "<cmd>ToggleTerm 1<CR>", "Terminal 1" },
  ['2'] = { "<cmd>ToggleTerm 2<CR>", "Terminal 2" },
  ['3'] = { "<cmd>ToggleTerm 3<CR>", "Terminal 3" },
  ['4'] = { "<cmd>ToggleTerm 4<CR>", "Terminal 4" },
  ['5'] = { "<cmd>ToggleTerm 5<CR>", "Terminal 5" },
  ['6'] = { "<cmd>ToggleTerm 6<CR>", "Terminal 6" },
  ['7'] = { "<cmd>ToggleTerm 7<CR>", "Terminal 7" },
  ['8'] = { "<cmd>ToggleTerm 8<CR>", "Terminal 8" },
  ['9'] = { "<cmd>ToggleTerm 9<CR>", "Terminal 9" },
  ['0'] = { "<cmd>ToggleTerm 10<CR>", "Terminal 10" },
}

-- Mappings for vim-visual-multi
vim.g.VM_default_mappings = 0
vim.g.VM_maps = {
  ["Select All"] = '<leader><C-a>',   -- Space + Ctrl + a
  ["Find Under"] = '<C-n>',           -- Ctrl + n
  ["Add Cursor Down"] = '<C-M-Down>', -- Ctrl + alt + Down Arrow
  ["Add Cursor Up"] = '<C-M-Up>',     -- Ctrl + alt + Up Arrow
}

-- Mappings for Spectre
lvim.builtin.which_key.mappings["S"] = {
  name = "+Spectre",
  S = { "<cmd>lua require('spectre').toggle()<CR>", "Toggle Spectre" },
  w = { "<cmd>lua require('spectre').open_visual({select_word=true})<CR>", "Search Word" },
  p = { "<cmd>lua require('spectre').open_file_search({select_word=true})<CR>", "Search in File" },
}


-- implement quickfix
local opts = { noremap = true, silent = true }
local function quickfix()
  vim.lsp.buf.code_action({
    filter = function(a) return a.isPreferred end,
    apply = true
  })
end
vim.keymap.set('n', '<leader>lq', quickfix, opts)

lvim.keys.normal_mode['<leader>rn'] = vim.lsp.buf.rename
lvim.keys.normal_mode["<leader>u"] = function()
  vim.cmd.UndotreeToggle()
  vim.cmd.UndotreeFocus()
end
lvim.builtin.which_key.mappings['u'] = { -- Removed <leader> since which_key already uses <leader>
  name = "UndoTree",
  u = {
    function()
      vim.cmd.UndotreeToggle()
      vim.cmd.UndotreeFocus()
    end,
    "Toggle & Focus UndoTree"
  },
}
