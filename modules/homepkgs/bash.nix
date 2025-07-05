{ lib, config, pkgs, ... }:
let
  inherit (config.local) homepkgs;
  inherit (homepkgs.bash) scripts;
in
{
  options.local.homepkgs.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    scripts = {
      fullrebuild.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      createpr.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = {
    programs.bash = {
      enable = homepkgs.bash.enable;
      shellAliases = lib.mkDefault {
        sudo = "sudo --preserve-env=EDITOR ";
      };
    };
    
    home.packages = let
      fullrebuild = pkgs.writeShellApplication {
        name = "home-fullrebuild";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gitMinimal
        ];
        runtimeEnv = {
          SCRIPT_PATH = homepkgs.repoPath;
        };
        text = (builtins.readFile ../scripts/fullrebuild.sh);
      };
      createpr = pkgs.writeShellApplication {
        name = "home-createpr";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gitMinimal
          pkgs.gh
        ];
        runtimeEnv = {
          SCRIPT_PATH = homepkgs.repoPath;
        };
        excludeShellChecks = [ "SC2001" ];
        text = (builtins.readFile ../scripts/createpr.sh);
      };
    in (
      lib.lists.optional scripts.fullrebuild.enable (fullrebuild)
      ++ lib.lists.optional scripts.createpr.enable (createpr)
    );
  };
}
