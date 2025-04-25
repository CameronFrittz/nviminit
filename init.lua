-- === PLUGINS ===
vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- LSP + Mason
  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'

  -- Autocompletion
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'
  use 'rafamadriz/friendly-snippets'

  -- Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end
  }
  use 'nvim-treesitter/nvim-treesitter-context'

  -- UI
  use 'nvim-lualine/lualine.nvim'
  use 'nvim-tree/nvim-tree.lua'
  use 'folke/tokyonight.nvim'

  -- Telescope
  use { 'nvim-telescope/telescope.nvim' }
  use 'nvim-lua/plenary.nvim'

  -- Copilot (Completions)
  use 'github/copilot.vim'

  -- Copilot Chat (Sidebar)
  use({
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    requires = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" },
    },
    config = function()
      require("CopilotChat").setup({
        debug = false,
        window = {
          layout = 'vertical',        -- use a vertical split (sidebar)
          width = 0.3,                -- 30% of editor width
          height = 0.9,               -- 90% of editor height
        },
        show_floating_preview = false,
        prompts = {
          Explain = "Explain how this code works:",
          Review = "Review this code:",
          Refactor = "Refactor this code to improve clarity:",
          Tests = "Suggest tests for this code:",
          Docs = "Generate documentation for this code:",
        },
        mappings = {
          accept = "<CR>",
          yank = "y",
          scroll_down = "<C-d>",
          scroll_up = "<C-u>",
          close = "q",
        },
      })
    end
  })

  -- Extras
  use 'folke/trouble.nvim'
  use 'j-hui/fidget.nvim'
  use 'ray-x/lsp_signature.nvim'
end)

-- === TELESCOPE SETUP ===
local ok, telescope = pcall(require, "telescope")
if ok then
  telescope.setup {
    defaults = {
      file_ignore_patterns = {
        "%.uid$",
        "%.godot$",
        "^%.git/",
        "^%.vs/",
        "^bin/",
      },
      mappings = {
        i = {
          ["<esc>"] = require("telescope.actions").close,
        }
      }
    }
  }
end


-- === GENERAL OPTIONS ===
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.clipboard = 'unnamedplus'
vim.cmd [[syntax on]]
vim.cmd [[filetype plugin indent on]]
vim.cmd [[colorscheme tokyonight]]

-- === KEYBINDINGS ===
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>')
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>')
vim.keymap.set('n', '<leader>cc', '<cmd>lua require("CopilotChat").toggle()<CR>')
vim.keymap.set('v', '<leader>ce', '<cmd>lua require("CopilotChat").ask("Explain")<CR>')

-- === LSP + MASON SETUP ===
require("mason").setup()
require("mason-lspconfig").setup {
  ensure_installed = { "omnisharp" },
}

local lspconfig = require("lspconfig")
local util = require("lspconfig.util")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason-lspconfig").setup_handlers {
  function(server_name)
    lspconfig[server_name].setup {
      capabilities = capabilities
    }
  end,
  ["omnisharp"] = function()
    local mason_registry = require("mason-registry")
    local omnisharp_pkg = mason_registry.get_package("omnisharp")
    local omnisharp_bin = omnisharp_pkg:get_install_path() .. "/libexec/OmniSharp.exe"

    lspconfig.omnisharp.setup {
      cmd = { omnisharp_bin },
      root_dir = util.root_pattern("*.sln"),
      enable_roslyn_analyzers = true,
      organize_imports_on_format = true,
      enable_import_completion = true,
      capabilities = capabilities,
      settings = {
        FormattingOptions = {
          enableEditorConfigSupport = true,
          OrganizeImports = true,
          enableMsBuildEditorConfigSupport = true,
          NewLine = "\n",
          UseTabs = false,
          TabSize = 4,
          IndentationSize = 4,
          EnableCommentFormatting = false,
        },
        RoslynExtensionsOptions = {
          enableAnalyzersSupport = true,
          enableImportCompletion = true,
          locationPaths = {},
          organizeImportsOnFormat = true,
          analyzeOpenDocumentsOnly = true,
          rules = {
            ["RCS1181"] = "none"
          }
        },
        RoslynAnalyzersOptions = {
          documentAnalysisScope = "openFiles"
        }
      },
      on_attach = function(client, bufnr)
        print("✅ OmniSharp attached")
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
        vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr })
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr })
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr })
        vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format { async = true } end, { buffer = bufnr })

        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })

        vim.api.nvim_create_autocmd("BufReadPost", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })

        require("fidget").setup {}
        require("lsp_signature").on_attach({}, bufnr)
      end
    }
  end
}

-- === AUTOCOMPLETION SETUP ===
local cmp = require("cmp")
cmp.setup {
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm { select = true },
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }
}

-- === TREESITTER SETUP ===
local treesitter_ok, configs = pcall(require, "nvim-treesitter.configs")
if treesitter_ok then
  configs.setup {
    ensure_installed = { "c_sharp", "html", "javascript", "css", "lua", "vim", "json", "ini", "gdscript" },
    highlight = {
      enable = true,
      disable = function(lang, buf)
        if lang == "c_sharp" then
          local ok, _ = pcall(vim.treesitter.get_parser, buf, lang)
          return not ok
        end
        return false
      end
    },
    context_commentstring = {
      enable = true
    }
  }
end

-- === GITHUB COPILOT ===
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-J>", "copilot#Accept(\"<CR>\")", { expr = true, silent = true, script = true })
vim.api.nvim_set_keymap("i", "<A-]>", "copilot#Next()", { expr = true, silent = true })
vim.api.nvim_set_keymap("i", "<A-[>", "copilot#Previous()", { expr = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-]>", "copilot#Dismiss()", { expr = true, silent = true })

vim.filetype.add({
  extension = {
    razor = "html"
  }
})


-- === NVIM-TREE SETUP ===
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  view = {
    width = 30,
    side = "left",
    preserve_window_proportions = true,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
    custom = { "^.git$", "^bin$", "^obj$", "^.vs$" },
  },
  git = {
    enable = true,
    ignore = false,
  },
})


vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Toggle File Explorer" })


