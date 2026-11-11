-- ============================================================================
-- Neovim config - modernized (lazy.nvim + native LSP + treesitter)
-- Backup of the old config: ~/.config/nvim.bak-20261107-1858
-- ============================================================================

-- Speed: bytecode cache for Lua modules
vim.loader.enable()

-- Leader must be set before lazy.nvim loads plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- Options
-- ============================================================================
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.background = "dark"

-- Indentation
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Editing
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.updatetime = 250
opt.timeoutlen = 400
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Whitespace rendering (kept from the old config, a bit less noisy)
opt.list = true
opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣" }

-- ============================================================================
-- lazy.nvim bootstrap
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- Plugins
-- ============================================================================
require("lazy").setup({
  -- Colorscheme ------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- UI ---------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "tokyonight",
        globalstatus = true,
        section_separators = "",
        component_separators = "|",
      },
    },
  },
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

  -- File tree --------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
      { "<leader>E", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in tree" },
    },
    config = function()
      require("nvim-tree").setup({
        view = { width = 32, side = "left" },
        renderer = {
          group_empty = true,
          highlight_git = true,
          indent_markers = { enable = true },
          icons = { show = { git = true, modified = true } },
        },
        filters = { dotfiles = false },
        git = { enable = true, ignore = true },
        update_focused_file = { enable = true },
        hijack_directories = { enable = true, auto_open = false },
      })
    end,
  },

  -- Fuzzy finder -----------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Workspace symbols" },
      { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      { "<leader>fF", "<cmd>Telescope find_files hidden=true<CR>", desc = "Find files (hidden)" },
      { "<leader>fG", "<cmd>Telescope live_grep additional_args={'--hidden','--no-ignore'}<CR>", desc = "Live grep (all files)" },
      { "<leader>f/", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          prompt_prefix = "  ",
          selection_caret = "  ",
          -- nvim-treesitter's main branch removed the API Telescope's previewer
          -- uses (ft_to_lang / configs); use Vim syntax highlighting instead.
          preview = { treesitter = false },
        },
      })
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- Treesitter (main branch API; must not be lazy-loaded) -----------------
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()
      require("nvim-treesitter").install({
        "lua", "vim", "vimdoc", "bash", "python",
        "javascript", "typescript", "tsx", "rust", "c", "cpp", "go",
        "json", "yaml", "toml", "markdown", "markdown_inline", "html", "css",
      })
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Git --------------------------------------------------------------------
  { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, opts = {} },

  -- Editing ----------------------------------------------------------------
  { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },
  { "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- LSP / Mason ------------------------------------------------------------
  { "williamboman/mason.nvim", cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" }, opts = { ui = { border = "rounded" } } },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.config("rust_analyzer", {})

      -- Only servers that exist on the system will actually start.
      vim.lsp.enable({
        "lua_ls", "rust_analyzer", "clangd", "gopls", "pyright", "ts_ls",
      })
    end,
  },

  -- Completion -------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources(
          { { name = "nvim_lsp" }, { name = "luasnip" } },
          { { name = "buffer" }, { name = "path" } }
        ),
      })
    end,
  },

  -- Copilot ----------------------------------------------------------------
  { "github/copilot.vim", event = "InsertEnter" },
}, {
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = false },
  change_detection = { notify = false },
  ui = { border = "rounded" },
})

-- Open the file tree on startup (without stealing focus from the file)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(function()
      local ok, api = pcall(require, "nvim-tree.api")
      if ok then
        api.tree.open({ focus = false })
      end
    end)
  end,
})

-- ============================================================================
-- Diagnostics
-- ============================================================================
vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

-- ============================================================================
-- Keymaps
-- ============================================================================
local map = vim.keymap.set

-- Save / quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Buffers
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Terminal
map("n", "<leader>t", "<cmd>terminal<CR>", { desc = "Terminal" })

-- BM25 code search (SQLite FTS5)
map("n", "<leader>fi", function() require("bm25").index() end, { desc = "BM25: index project" })
map("n", "<leader>fB", function() require("bm25").search() end, { desc = "BM25: code search" })
map("n", "<leader>fW", function() require("bm25").search_word() end, { desc = "BM25: search word under cursor" })

-- LSP keymaps (per buffer)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local function bmap(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
    end
    bmap("gd", vim.lsp.buf.definition, "Goto definition")
    bmap("gD", vim.lsp.buf.declaration, "Goto declaration")
    bmap("gr", vim.lsp.buf.references, "References")
    bmap("gI", vim.lsp.buf.implementation, "Implementation")
    bmap("K", vim.lsp.buf.hover, "Hover")
    bmap("<leader>rn", vim.lsp.buf.rename, "Rename")
    bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
    bmap("<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format")
    bmap("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
    bmap("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
  end,
})

-- ============================================================================
-- Autocmds
-- ============================================================================
-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ============================================================================
-- Neovide
-- ============================================================================
if vim.g.neovide then
  vim.o.guifont = "Source Code Pro:h14"
  vim.opt.linespace = 0
  vim.g.neovide_scale_factor = 1.0
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0
  vim.g.neovide_transparency = 0.8
  vim.g.neovide_refresh_rate = 60
  vim.g.neovide_cursor_vfx_mode = "railgun"
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_length = 0.05
  vim.g.neovide_underline_automatic_scaling = false

  vim.g.gui_font_default_size = 14
  vim.g.gui_font_size = vim.g.gui_font_default_size
  vim.g.gui_font_face = "Source Code Pro"

  local function refresh_font()
    vim.opt.guifont = string.format("%s:h%s", vim.g.gui_font_face, vim.g.gui_font_size)
  end

  local function resize_font(delta)
    vim.g.gui_font_size = vim.g.gui_font_size + delta
    refresh_font()
  end

  local function reset_font()
    vim.g.gui_font_size = vim.g.gui_font_default_size
    refresh_font()
  end

  refresh_font()
  vim.keymap.set({ "n", "i" }, "<C-+>", function() resize_font(1) end, { silent = true })
  vim.keymap.set({ "n", "i" }, "<C-->", function() resize_font(-1) end, { silent = true })
  vim.keymap.set({ "n", "i" }, "<C-BS>", reset_font, { silent = true })
end
