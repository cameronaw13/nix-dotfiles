{ lib, config, ... }:
{
  options.local.homepkgs.vim.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf config.local.homepkgs.vim.enable {
    programs.vim = {
      enable = lib.mkDefault true;
      defaultEditor = true;
      extraConfig = ''
        " visual "
        syntax enable
        set linebreak
        set display+=lastline
        set laststatus=0

        " indentation "
        set softtabstop=2
        set shiftwidth=2
        set expandtab
        set backspace=indent,eol,start
        set cpoptions+=I

        " search "
        set hlsearch
        set ignorecase
        set smartcase
        set incsearch

        " cursor "
        set ruler
        set whichwrap+=<,>,[,]

        " behavior "
        set history=500

        " write to sudo "
        command W :execute ':w !sudo tee % >/dev/null' | :edit!
        command Wq :execute ':w !sudo tee % >/dev/null' | :q!
        au BufEnter * set noro
      '';
    };
  };
}
