{ lib, config, pkgs, inputs, ... }:
let
  inherit (config.local) homepkgs;
in
{
  options.local.homepkgs.neovim = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    aliases = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.singleLineStr);
      default = null;
    };
  };

  config.nixCats = {
    inherit (homepkgs.neovim) enable;
    nixpkgs_version = inputs.nixpkgs;
    packageNames = [ "home-nvim" ];
    luaPath = ./.;

    categoryDefinitions.replace = { pkgs, ... }: {
      startupPlugins = {
        general = lib.lists.flatten [
          (builtins.attrValues {
            inherit (pkgs.vimPlugins)
            fzf-lua
            undotree
            indent-blankline-nvim
            ;
          })
          (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: builtins.attrValues {
            inherit (plugins)
            nix
            vim
            lua
            ;
          }))
        ];
        wheel = builtins.attrValues {
          inherit (pkgs.vimPlugins)
          vim-suda
          ;
        };
      };
    };

    packageDefinitions.replace = {
      home-nvim = { ... }: {
        settings = {
          inherit (homepkgs.neovim) aliases;
          wrapRc = false;
          suffix-path = true;
          suffix-LD = true;
        };
        categories = {
          general = true;
          wheel = homepkgs.isWheel;
        };
      };
    };
  };
}
