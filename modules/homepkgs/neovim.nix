{ lib, config, pkgs, ... }: 
let
  inherit (config.local) homepkgs;
in
{
  options.local.homepkgs.neovim = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    vimAlias = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    programs.neovim = {
      enable = homepkgs.neovim.enable;
      inherit (homepkgs.neovim) defaultEditor vimAlias;
      plugins = lib.mkDefault ((builtins.attrValues {
        inherit (pkgs.vimPlugins)
        fzf-lua
        undotree
        ;
      }) ++ [
        (lib.mkIf homepkgs.isWheel {
          plugin = pkgs.vimPlugins.vim-suda;
          config = ''
            let g:suda_smart_edit = 1
          '';
        })
      ]);
      extraConfig = lib.mkDefault ''
        " visual "
        set nu rnu

        " indentation "
        set softtabstop=2
        set shiftwidth=2
        set expandtab
        set cpoptions+=I
      '';
    };
  };
}
