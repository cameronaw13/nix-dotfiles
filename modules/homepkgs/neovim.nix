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
  };

  config = lib.mkIf homepkgs.neovim.enable {
    programs.neovim = {
      enable = true;
      inherit (homepkgs.neovim) defaultEditor;
      vimAlias = true;
      plugins = with pkgs.vimPlugins; [
        fzf-lua
        (lib.mkIf homepkgs.isWheel {
          plugin = vim-suda;
          config = ''
            let g:suda_smart_edit = 1
          '';
        })
      ];
      extraConfig = ''
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
