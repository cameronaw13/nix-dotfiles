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
      path = lib.mkOption {
        type = lib.types.path;
        default = "/etc/nixos";
      };
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

  config = lib.mkIf homepkgs.bash.enable {
    programs.bash = {
      enable = true;
      shellAliases = {
        sudo = "sudo --preserve-env=VISUAL ";
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
          SCRIPT_PATH = scripts.path;
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
          SCRIPT_PATH = scripts.path;
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
