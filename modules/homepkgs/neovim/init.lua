--[[ OPTIONS ]]--
-- visual --
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.breakindent = true

-- indentation --
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.cpoptions:append('I')

-- undo --
vim.opt.undofile = true

--[[ KEYMAPS ]]--
-- leader --
--vim.keymap.set('', '<Space>', '<Nop>')
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--[[ PLUGINS ]]--
-- general --
if nixCats('lua.general') then
  -- fzf-lua --
  require('fzf-lua').setup({'border-fused'})

  -- undotree --
  vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)

  -- indent-blankline --
  require('ibl').setup {
    indent = {
      char = '▏',
      smart_indent_cap = false
    }
  }

  -- tree-sitter --
  require('nvim-reesitter.configs').setup {
    ensure_installed = { }
  }
end

-- wheel --
if nixCats('lua.wheel') then
  vim.g.suda_smart_edit = 1
end

-- treesitter --
--if nixCats('lua.treesitter') then
--  require('nvim-treesitter.configs').setup {
--    ensure_installed = { }
--  }
--end
