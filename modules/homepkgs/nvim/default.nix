{ lib, config, inputs, repoPath, ... }:
let
  inherit (config.local) homepkgs;
in
{
  options.local.homepkgs.nvim = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    aliases = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.singleLineStr);
      default = null;
    };
    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    wrapRc = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
  
  config = {
    nixCats = {
      inherit (homepkgs.nvim) enable;
      nixpkgs_version = inputs.nixpkgs;
      packageNames = [ "home-nvim" ];
      luaPath = ./.;
      categoryDefinitions.replace = { pkgs, ... }: {
        startupPlugins = {
          general = builtins.attrValues {
            inherit (pkgs.vimPlugins)
            fzf-lua
            undotree
            indent-blankline-nvim
            comment-nvim
            gitsigns-nvim
            render-markdown-nvim
            ;
          };
          wheel = builtins.attrValues {
            inherit (pkgs.vimPlugins)
            vim-suda
            ;
          };
          treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
            plugins: builtins.attrValues {
              inherit (plugins)
              nix
              vim
              lua
              bash
              yaml
              toml
              kdl
              ;
            }
          );
        };
      };
      
      packageDefinitions.replace = {
        home-nvim = _: {
          settings = {
            inherit (homepkgs.nvim) aliases wrapRc;
            unwrappedCfgPath = lib.mkIf (!homepkgs.nvim.wrapRc) "${repoPath}/modules/homepkgs/nvim";
            suffix-path = true;
            suffix-LD = true;
          };
          categories = {
            general = true;
            wheel = homepkgs.isWheel;
            treesitter = false;
          };
        };
      };
    };

    home.sessionVariables = lib.mkIf homepkgs.nvim.defaultEditor {
      EDITOR = "home-nvim";
    };
  };
}
