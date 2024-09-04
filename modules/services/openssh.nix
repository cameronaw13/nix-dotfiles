{ lib, config, ... }:
let
  inherit (config.local) services;
in
{
  options.local.services.openssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf services.openssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = "no";
      };
    };
    networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
  };
}
