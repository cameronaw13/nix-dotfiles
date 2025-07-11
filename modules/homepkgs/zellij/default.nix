{ lib, config, ... }:
let
  inherit (config.local) homepkgs;
in
{
  options.local.homepkgs.zellij = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    programs.zellij = {
      inherit (homepkgs.zellij) enable;
      enableBashIntegration = lib.mkDefault homepkgs.bash.enable;
      attachExistingSession = lib.mkDefault true;
    };

    xdg.configFile."zellij/config.kdl" = lib.mkDefault {
      inherit (homepkgs.zellij) enable;
      source = ./config.kdl;
      force = lib.mkDefault true;
    };
  };
}
