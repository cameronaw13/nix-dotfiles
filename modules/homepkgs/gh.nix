{ lib, config, ... }:
let
  inherit (config.local) homepkgs;
in
{
  options.local.homepkgs.git.gh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (homepkgs.git.enable && homepkgs.git.gh.enable) {
    programs.gh = {
      enable = lib.mkDefault true;
      settings.git_protocol = "ssh";
    };
  };
}
    
