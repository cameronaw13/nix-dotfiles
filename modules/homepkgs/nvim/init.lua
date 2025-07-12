--[[ KEYMAPS ]]--
-- leader --
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--[[ OPTIONS ]]--
-- visual --
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.breakindent = true
vim.opt.list = true
vim.opt.listchars = "tab:⇥ ,trail:·,nbsp:⍽"

-- indentation --
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.cpoptions:append('I')

--[[ PLUGINS ]]--
-- general --
if nixCats('general') then
  -- fzf-lua --
  require('fzf-lua').setup({'border-fused'})
  vim.keymap.set('n', '<leader>f', vim.cmd.FzfLua)
  
  -- undotree --
  vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
  vim.opt.undofile = true

  -- indent-blankline
  require('ibl').setup {
    indent = {
      char = '▏',
      smart_indent_cap = false
    },
    scope = {
      enabled = false
    }
  }

  -- comment --
  require('Comment').setup()

  -- gitsigns --
  require('gitsigns').setup()

  -- render-markdown --
  require('render-markdown').setup()
end

-- wheel --
if nixCats('wheel') then
  vim.g.suda_smart_edit = 1
end

-- treesitter --
if nixCats('treesitter') then
  require('nvim-treesitter.configs').setup {
    highlight = {
      enable = true
    }
  }
end
