" General Settings
set number
set relativenumber
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab
set expandtab
set autoindent
set list
set listchars=tab:▸\ ,trail:·
set clipboard=unnamedplus
set encoding=UTF-8

syntax on
filetype plugin on

" Plugin Configuration
call plug#begin('~/.config/nvim/plugged')

" Color schemes
Plug 'joshdick/onedark.vim'
Plug 'iCyMind/NeoSolarized'
Plug 'folke/tokyonight.nvim'
Plug 'doki-theme/doki-theme-vim'
Plug 'NLKNguyen/papercolor-theme'

" Development Enhancements
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/vim-easy-align'
Plug 'sheerun/vim-polyglot'
Plug 'jiangmiao/auto-pairs'

" Neovim-specific Plugins
if has('nvim')
  Plug 'nvim-tree/nvim-web-devicons' " optional for enhanced file icons
  Plug 'nvim-tree/nvim-tree.lua'
  Plug 'github/copilot.vim'
  Plug 'hrsh7th/vim-vsnip-integ'
  Plug 'hrsh7th/vim-vsnip'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'gelguy/wilder.nvim', { 'do': ':UpdateRemotePlugins' } " for enhanced command-line completion
endif

call plug#end()

" UI Enhancements for Neovide
if exists('g:neovide')
  let g:neovide_underline_automatic_scaling = v:false
  let g:neovide_cursor_vfx_mode = "railgun"
  let g:neovide_cursor_animation_length = 0.05
  let g:neovide_cursor_trail_length = 0.05
endif

" wilder.nvim Configuration for Enhanced Navigation
call wilder#setup({'modes': [':', '/', '?']})
call wilder#set_option('renderer', wilder#popupmenu_renderer(wilder#popupmenu_border_theme({
        \ 'highlighter': wilder#basic_highlighter(),
        \ 'left': [' ', wilder#popupmenu_devicons()],
        \ 'right': [' ', wilder#popupmenu_scrollbar()],
      \ })))
" Default color scheme
colorscheme PaperColor

" Snippet Expansion and Navigation
imap <expr> <C-j> vsnip#expandable() ? '<Plug>(vsnip-expand)' : '<C-j>'
smap <expr> <C-j> vsnip#expandable() ? '<Plug>(vsnip-expand)' : '<C-j>'
imap <expr> <C-l> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <C-l> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
imap <expr> <Tab> vsnip#jumpable(1) ? '<Plug>(vsnip-jump-next)' : '<Tab>'
smap <expr> <Tab> vsnip#jumpable(1) ? '<Plug>(vsnip-jump-next)' : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'


